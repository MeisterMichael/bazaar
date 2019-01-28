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

		def calculate( obj, args = {} )

			args[:discount] ||= {}
			args[:shipping] ||= {}
			args[:tax] ||= {}
			args[:transaction] ||= {}

			self.calculate_order_before( obj, args ) if obj.is_a? Bazaar::Order

			shipping_response					= @shipping_service.calculate( obj, args[:shipping] )
			discount_pretax_response	= @discount_service.calculate( obj, args[:discount].merge( pre_tax: true ) ) # calculate discounts pre-tax
			tax_response							= @tax_service.calculate( obj, args[:tax] )
			discount_response					= @discount_service.calculate( obj, args[:discount] ) # calucate again after taxes
			transaction_response			= @transaction_service.calculate( obj, args[:transaction] )

			self.calculate_order_after( obj, args ) if obj.is_a? Bazaar::Order

			{
				shipping: shipping_response,
				discount_pretax: discount_pretax_response,
				discount: discount_response,
				tax: tax_response,
				transaction: transaction_response,
			}
		end

		def discount_service
			@discount_service
		end

		def fraud_service
			@fraud_service
		end

		def process( order, args = {} )

			args[:discount] ||= {}
			args[:shipping] ||= {}
			args[:tax] ||= {}
			args[:transaction] ||= {}

			# Save as a failed before processing... assuming failure (in case of
			# unrecoverable error) and recognizing success.
			order_status = order.status.to_s
			return nil unless order.update( status: 'failed' )

			self.calculate( order, args )
			return nil unless self.validate( order, args )

			return self.process_capture_payment_method( order, args ) if order_status == 'pre_order'
			return self.process_purchase( order, args ) if order_status == 'active'
			raise Exception.new( 'OrderService#process: invalid order status' )
		end

		def process_purchase( order, args = {} )

			if order.total == 0
				@transaction_service.capture_payment_method( order, args[:transaction] ) unless order.parent.is_a? Bazaar::Subscription

				if order.nested_errors.blank?

					order.payment_status = 'paid'
					order.status = 'active'
					order.save

				end

			else

				transaction = @transaction_service.process( order, args[:transaction] )

				if transaction && transaction.approved?

					order.payment_status = 'paid'
					order.status = 'active'
					order.save

					log_event( user: order.user, name: 'transaction_sxs', on: order, content: "transaction was approved for #{order.total_formatted} on Order #{order.code}" )

					self.process_purchase_success( order, args )

				else

					if transaction && transaction.declined?
						log_event( user: order.user, name: 'transaction_failed', on: order, content: "transaction was denied for #{order.total_formatted} on Order #{order.code}: #{transaction.message}" )
					else
						log_event( user: order.user, name: 'transaction_failed', on: order, content: "transaction was denied for #{order.total_formatted} on Order #{order.code}" )
					end

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

			begin
				@tax_service.process( order ) if @tax_service.respond_to? :process
			rescue Exception => e
				puts e.message
				NewRelic::Agent.notice_error(e) if defined?( NewRelic )
			end

			if order.user.nil? && order.email.present? && Bazaar.create_user_on_checkout

				order.user = User.create_with( first_name: order.billing_address.first_name, last_name: order.billing_address.last_name ).find_or_create_by( email: order.email.downcase )
				order.billing_address.user = order.shipping_address.user = order.user
				order.save

			end

			payment_profile_expires_at = Bazaar::TransactionService.parse_credit_card_expiry( transaction_options[:credit_card][:expiration] ) if transaction_options[:credit_card].present?
			@subscription_service.subscribe_ordered_plans( order, payment_profile_expires_at: payment_profile_expires_at ) if @subscription_service.present? && order.active?

			true
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
			@shipping_service.validate( order.shipping_address )
			@shipping_service.validate( order.billing_address )
			@fraud_service.validate( order ) if @fraud_service

			return not( order.nested_errors.present? )
		end

		protected
		def calculate_order_before( order, args = {} )

			order.subtotal = order.order_items.select(&:prod?).sum(&:subtotal)
			order.status = 'pre_order' if order.order_items.select{|order_item| order_item.item.respond_to?( :pre_order? ) && order_item.item.pre_order? }.present?

		end

		def calculate_order_after( order, args = {} )

			order.total = order.order_items.sum(&:subtotal)

		end

		def process_capture_payment_method( order, args = {} )
			transaction = @transaction_service.capture_payment_method( order, args[:transaction] )
			order.save

			transaction
		end
	end

end
