module SwellEcom

	class WholesaleOrderService < SwellEcom::OrderService
		# abstract

		def initialize( args = {} )

			@shipping_service		= args[:shipping_service]
			@shipping_service		||= SwellEcom.wholesale_shipping_service_class.constantize.new( SwellEcom.wholesale_shipping_service_config )

			@tax_service			= args[:tax_service]
			@tax_service			||= SwellEcom.wholesale_tax_service_class.constantize.new( SwellEcom.wholesale_tax_service_config )

			@transaction_service	= args[:transaction_service]
			@transaction_service	||= SwellEcom.wholesale_transaction_service_class.constantize.new( SwellEcom.wholesale_transaction_service_config )

			@discount_service		= args[:discount_service]
			@discount_service		||= SwellEcom.wholesale_discount_service_class.constantize.new( SwellEcom.wholesale_discount_service_config )

		end
	end

end
