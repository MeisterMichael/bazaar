module Bazaar

	class OrderService < ::ApplicationService
		# abstract

		def initialize( args = {} )

			@fraud_service		= args[:fraud_service]
			@fraud_service		||= Bazaar.fraud_service_class.constantize.new( Bazaar.fraud_service_config )

			@shipping_service		= args[:shipping_service]
			@shipping_service		||= Bazaar.shipping_service_class.constantize.new( Bazaar.shipping_service_config )

			@tax_service			= args[:tax_service]
			@tax_service			||= Bazaar.tax_service_class.constantize.new( Bazaar.tax_service_config )

			@transaction_service	= args[:transaction_service]
			@transaction_service	||= Bazaar.transaction_service_class.constantize.new( Bazaar.transaction_service_config )

			@discount_service		= args[:discount_service]
			@discount_service		||= Bazaar.discount_service_class.constantize.new( Bazaar.discount_service_config )

			@subscription_service = args[:subscription_service]
			@subscription_service		||= Bazaar.subscription_service_class.constantize.new( Bazaar.subscription_service_config.merge( order_service: self ) )

		end

		def apply_discount?( obj )
			true
		end

		def apply_tax?( obj )
			true
		end

		def calculate( obj, args = {} )

			args[:order] ||= {}
			args[:discount] ||= {}
			args[:shipping] ||= {}
			args[:tax] ||= {}
			args[:transaction] ||= {}

			self.calculate_order_before( obj, args ) if obj.is_a? Bazaar::Order

			shipping_response						= @shipping_service.calculate( obj, args[:shipping] )
			discount_pre_tax_response		= @discount_service.calculate_pre_tax( obj, args[:discount] ) if apply_discount?( obj ) # calculate discounts pre-tax
			tax_response								= @tax_service.calculate( obj, args[:tax] ) if apply_tax?( obj )
			discount_post_tax_response	= @discount_service.calculate_post_tax( obj, args[:discount] ) if apply_discount?( obj ) # calucate again after taxes
			transaction_response				= @transaction_service.calculate( obj, args[:transaction] )

			self.calculate_order_after( obj, args ) if obj.is_a? Bazaar::Order

			{
				shipping: shipping_response,
				discount_pre_tax: discount_pre_tax_response,
				discount_post_tax: discount_post_tax_response,
				tax: tax_response,
				transaction: transaction_response,
			}
		end

		def calculate_order_status( order, args = {} )
			order.status.to_s
		end

		def create_order_transaction( order, attributes = {} )
			transaction = Bazaar::Transaction.create({
				transaction_type: 'charge',
				status: 'declined',
				parent_obj_id: order.id,
				parent_obj_type: order.class.base_class.name,
				billing_address_id: order.billing_address_id,
				provider: order.provider,
				transaction_provider: order.transaction_provider,
				merchant_identification: order.merchant_identification,
				currency: order.currency,
				amount: order.total,
				message: order.nested_errors.join('. '),
			}.merge(attributes))

			transaction
		end

		def discount_service
			@discount_service
		end

		def fraud_service
			@fraud_service
		end

		def process( order, args = {} )

			args[:order] ||= {}
			args[:discount] ||= {}
			args[:shipping] ||= {}
			args[:tax] ||= {}
			args[:transaction] ||= {}

			# Save as a failed before processing... assuming failure (in case of
			# unrecoverable error) and recognizing success.
			order_status = calculate_order_status( order, args )
			return nil unless order.update( status: 'failed', payment_status: 'payment_failed' )

			self.calculate( order, args )
			unless self.validate( order, args )
				return create_order_transaction( order, transaction_type: 'charge', status: 'declined' )
			end

			if order_status == 'pre_order'
				result = self.process_capture_payment_method( order, args.merge( success_status: 'pre_order' ) )
			elsif order_status == 'active'
				result = self.process_purchase( order, args )
			else
				raise Exception.new( 'OrderService#process: invalid order status' )
			end

			result
		end

		def process_purchase( order, args = {} )

			if order.total == 0
				# There is only a change of declining when capturing, otherise it is
				# approved for $0, and we already have the payment method details.
				transaction_status = 'approved'
				transaction_type = 'charge'
				result = true

				if require_capture_payment_method?( order, args )
					transaction_type = 'preauth'
					result = @transaction_service.capture_payment_method( order, args[:transaction] )
					transaction_status = 'declined' unless result
				end

				transaction = create_order_transaction( order, transaction_type: transaction_type, status: transaction_status )

				if transaction.approved?
					order.payment_status = 'paid'
					order.status = 'active'
					order.save

					log_event( user: order.user, name: 'transaction_sxs', on: order, content: "transaction was approved for #{order.total_formatted} on Order #{order.code}. #{transaction.message}" )

					self.process_purchase_success( order, args )
				else
					order.status = 'failed' unless order.trash?
					order.payment_status = 'declined'
					order.save

					log_event( user: order.user, name: 'transaction_failed', on: order, content: "transaction was denied for #{order.total_formatted} on Order #{order.code}: #{transaction.message}." )

					self.process_purchase_failure( order, args )
				end

			else

				transaction = @transaction_service.process( order, args[:transaction] )

				# @TODO ensure that all process calls return a transaction.  THen remove this.
				transaction = create_order_transaction( order, transaction_type: 'charge', status: 'declined' ) unless transaction

				if transaction.approved?

					order.payment_status = 'paid'
					order.status = 'active'
					order.save

					log_event( user: order.user, name: 'transaction_sxs', on: order, content: "transaction was approved for #{order.total_formatted} on Order #{order.code}. #{transaction.message}" )

					self.process_purchase_success( order, args )

				else

					order.status = 'failed' unless order.trash?
					order.payment_status = 'declined'
					order.save

					log_event( user: order.user, name: 'transaction_failed', on: order, content: "transaction was denied for #{order.total_formatted} on Order #{order.code}: #{transaction.message}." )

					self.process_purchase_failure( order, args )

				end

			end


			transaction

		end

		def process_purchase_failure( order, args )

			order.errors.add(:base, :processing_error, message: "Transaction was declined for #{order.total_formatted}" )

		end

		def process_purchase_success( order, args = {} )
			transaction_options = args[:transaction] || {}

			if apply_tax?( order )
				begin
					@tax_service.process( order ) if @tax_service.respond_to? :process
				rescue Exception => e
					puts e.message
					NewRelic::Agent.notice_error(e) if defined?( NewRelic )
				end
			end

			if order.user.nil? && order.email.present? && Bazaar.create_user_on_checkout

				order.user = User.create_with( first_name: order.billing_address.first_name, last_name: order.billing_address.last_name ).find_or_create_by( email: order.email.downcase )
				order.billing_user_address.user = order.shipping_user_address.user = order.user
				order.save

			end

			payment_profile_expires_at = Bazaar::TransactionService.parse_credit_card_expiry( transaction_options[:credit_card][:expiration] ) if transaction_options[:credit_card].present?
			@subscription_service.subscribe_ordered_plans( order, payment_profile_expires_at: payment_profile_expires_at ) if @subscription_service.present? && not( order.pre_order? )

			order.shipments.not_negative_status.each do |shipment|
				@shipping_service.process_shipment( shipment )
			end

			true
		end

		def recalculate( obj, args = {} )

			args[:order] ||= {}
			args[:discount] ||= {}
			args[:shipping] ||= {}
			args[:tax] ||= {}
			args[:transaction] ||= {}

			if obj.is_a? Bazaar::Order
				obj.order_skus.each { |order_sku| order_sku.quantity = 0 }
				self.calculate_order_before( obj, args )
			end

			shipping_response						= @shipping_service.recalculate( obj, args[:shipping] )
			discount_pre_tax_response		= @discount_service.recalculate_pre_tax( obj, args[:discount] ) if apply_discount?( obj ) # calculate discounts pre-tax
			tax_response								= @tax_service.recalculate( obj, args[:tax] ) if apply_tax?( obj )
			discount_post_tax_response	= @discount_service.recalculate_post_tax( obj, args[:discount] ) if apply_discount?( obj ) # calucate again after taxes
			transaction_response				= @transaction_service.recalculate( obj, args[:transaction] )

			self.calculate_order_after( obj, args ) if obj.is_a? Bazaar::Order

			{
				shipping: shipping_response,
				discount_pre_tax: discount_pre_tax_response,
				discount_post_tax: discount_post_tax_response,
				tax: tax_response,
				transaction: transaction_response,
			}
		end

		def refund( args = {} )

			@transaction_service.refund( args || {} )

		end

		def shipping_service
			@shipping_service
		end

		def subscription_service
			@subscription_service
		end

		def tax_service
			@tax_service
		end

		def transaction_service
			@transaction_service
		end

		def validate( order, args )
			return false if order.nested_errors.present?

			order.validate
			@shipping_service.validate( order.shipping_user_address )
			@shipping_service.validate( order.billing_user_address )
			@fraud_service.validate( order ) if @fraud_service

			return not( order.nested_errors.present? )
		end


		def calculate_order_items( order, args = {} )
			order.order_offers.to_a.each do |order_offer|
				item = order_offer.offer.product
				item = Bazaar::SubscriptionPlan.where( offer: order_offer.offer ).first if order_offer.offer.recurring?
				item = order_offer.subscription if order_offer.subscription_interval > 1

				prod_order_items = order.order_items.to_a.select{ |order_item| order_item.order_item_type == 'prod' }

				order_item = prod_order_items.find{ |order_item| order_item.offer == order_offer.offer }
				order_item ||= prod_order_items.find{ |order_item| order_item.item == item }
				order_item ||= order.order_items.new( order_item_type: 'prod', item: item, offer: order_offer.offer )
				order_item.attributes = {
					quantity: order_offer.quantity,
					title: order_offer.title,
					price: order_offer.price,
					subtotal: order_offer.subtotal,
				}

			end
		end

		def calculate_order_offers( order, args = {} )
		end

		def calculate_order_skus( order, args = {} )
			order.order_skus = []
			order.order_offers.each do |order_offer|

				offer_interval = order_offer.offer_interval || 1

				order_offer.offer.offer_skus.active.for_interval( offer_interval ).each do |offer_sku|
					order_sku = order_offer.order.order_skus.to_a.find{ |order_sku| order_sku.sku == offer_sku.sku }
					order_sku ||= order_offer.order.order_skus.new( sku: offer_sku.sku, quantity: 0 )
					order_sku.quantity = order_sku.quantity + offer_sku.calculate_quantity( order_offer.quantity )
					order_sku.shipping_calculation_exemptions = order_sku.shipping_calculation_exemptions + offer_sku.calculate_shipping_calculation_exemptions( order_offer.quantity )
				end
			end
		end

		def require_capture_payment_method?( order, args = {} )
			# DO NOT require payment method capture if the order is a renewal, however
			# DO require payment method capture if the order has a non-zero amount
			# OR contains subscriptions that require a captured payment method
			not( order.subscription_renewal? ) && ( order.total.to_i > 0 || has_renewals_that_require_capture_payment_method?( order, args ) )
		end

		def has_renewals_that_require_capture_payment_method?( order, args = {} )
			# for now we assume that any order with recurring offers requires payment
			# capture... until full solution can be implemented.
			return order.with_recurring_offers?

			# @todo determine if any subsiquent orders require payment capturing.
			# shipping and other fees should be taken into account.

			# # If any of the offers contain renewals with non-zero prices, then the
			# # order would indeed require capture payment method
			# non_zero_price_offers = []
			# order.order_offers.to_a.select do |order_offer|
			# 	offer = order_offer.offer
			# 	if offer.offer_prices.active.where( 'price > 0' ).present?
			# 		non_zero_price_offers << offer
			# 	end
			# end
			# non_zero_price_offers.present?
		end

		protected

		def calculate_order_before( order, args = {} )

			self.calculate_order_offers( order, args )
			self.calculate_order_skus( order, args )
			self.calculate_order_items( order, args )

			order.subtotal = order.order_offers.to_a.sum(&:subtotal)
		end

		def calculate_order_after( order, args = {} )

			order.total = order.tax + order.shipping + order.subtotal - order.discount

		end

		def process_capture_payment_method( order, args = {} )
			result = @transaction_service.capture_payment_method( order, args[:transaction] )
			transaction_status = 'declined'
			transaction_status = 'approved' if result

			transaction = create_order_transaction( order, transaction_type: 'preauth', status: transaction_status )

			if transaction.approved?

				order.payment_status = 'payment_method_captured'
				order.status = args[:success_status] || 'active'
				order.save

				log_event( user: order.user, name: 'transaction_sxs', on: order, content: "transaction payment capture was approved for #{order.total_formatted} on Order #{order.code}" )

			else

				order.payment_status = 'declined'
				order.status = 'failed'
				order.save

				log_event( user: order.user, name: 'transaction_failed', on: order, content: "transaction payment capture was denied for #{order.total_formatted} on Order #{order.code}: #{transaction.message}" )

			end

			transaction
		end
	end

end
