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

			@shipping_service.calculate( obj, args[:shipping] )
			@discount_service.calculate_pre_tax( obj, args[:discount] )
			@tax_service.calculate( obj, args[:tax] )
			@discount_service.calculate_post_tax( obj, args[:discount] )
			@transaction_service.calculate( obj, args[:transaction] )

		end

		def process( order, args = {} )

			@shipping_service.calculate( order, args[:shipping] )
			@discount_service.calculate_pre_tax( order, args[:discount] )
			@tax_service.calculate( order, args[:tax] )
			@discount_service.calculate_post_tax( order, args[:discount] )
			
			if order.errors.present?
				@transaction_service.calculate( obj, args[:transaction] )
			else
				@transaction_service.process( order, args[:transaction] )
			end

		end

		def refund( args = {} )

			@transaction_service.refund( args )

		end

	end

end
