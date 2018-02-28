module SwellEcom

	class OrderService
		# abstract

		def initialize( args = {} )

			@shipping_service		= args[:shipping_service]
			@shipping_service		||= SwellEcom.shipping_service_class.constantize.new( SwellEcom.shipping_service_config )

			@tax_service			= args[:tax_service]
			@tax_service			||= SwellEcom.tax_service_class.constantize.new( SwellEcom.tax_service_config )

			@transaction_service	= args[:transaction_service]
			@transaction_service	||= SwellEcom.transaction_service_class.constantize.new( SwellEcom.transaction_service_config )

			@discount_service		= args[:discount_service]
			@discount_service		||= SwellEcom.discount_service_class.constantize.new( SwellEcom.discount_service_config )

		end

		def calculate( obj, args = {} )

			args[:discount] ||= {}
			args[:shipping] ||= {}
			args[:tax] ||= {}
			args[:transaction] ||= {}

			self.calculate_order( obj, args ) if obj.is_a? SwellEcom::Order

			@shipping_service.calculate( obj, args[:shipping] )
			@discount_service.calculate( obj, args[:discount].merge( pre_tax: true ) ) # calculate discounts pre-tax
			@tax_service.calculate( obj, args[:tax] )
			@discount_service.calculate( obj, args[:discount] ) # calucate again after taxes
			@transaction_service.calculate( obj, args[:transaction] )

		end

		def process( order, args = {} )

			args[:discount] ||= {}
			args[:shipping] ||= {}
			args[:tax] ||= {}
			args[:transaction] ||= {}

			self.calculate( order, args )
			return nil unless self.validate( order, args )

			return self.process_capture_payment_method( order, args ) if order.pre_order?
			return self.process_purchase( order, args ) if order.active?
			raise Exception.new( 'OrderService#process: invalid order status' )
		end

		def process_purchase( order, args = {} )

			if order.total == 0
				order.payment_status = 'paid'
				order.save
			else
				transaction = @transaction_service.process( order, args[:transaction] )
			end

			order.active!

			begin
				@tax_service.process( order ) if @tax_service.respond_to? :process
			rescue Exception => e
				puts e.message
				NewRelic::Agent.notice_error(e) if defined?( NewRelic )
			end

			transaction

		end

		def refund( args = {} )

			@transaction_service.refund( args || {} )

		end

		def validate( order, args )
			order.validate
			@shipping_service.validate( order.shipping_address )
			@shipping_service.validate( order.billing_address )
			return not( order.errors.present? || order.shipping_address.errors.present? || order.billing_address.errors.present? )
		end

		protected
		def calculate_order( order, args = {} )

			order.subtotal = order.order_items.select(&:prod?).sum(&:subtotal)
			order.status = 'pre_order' if order.order_items.select{|order_item| order_item.item.respond_to?( :pre_order? ) && order_item.item.pre_order? }.present?

		end

		def process_capture_payment_method( order, args = {} )
			if order.total == 0
				order.payment_status = 'payment_method_captured'
				order.save
			else
				@transaction_service.capture_payment_method( order, args[:transaction] )
			end
		end
	end

end
