module BazaarCore

	class WholesaleOrderService < BazaarCore::OrderService
		# abstract

		def initialize( args = {} )

			@fraud_service		= args[:fraud_service]
			@fraud_service		||= BazaarCore.fraud_service_class.constantize.new( BazaarCore.fraud_service_config )

			@shipping_service		= args[:shipping_service]
			@shipping_service		||= BazaarCore.wholesale_shipping_service_class.constantize.new( BazaarCore.wholesale_shipping_service_config )

			@tax_service			= args[:tax_service]
			@tax_service			||= BazaarCore.wholesale_tax_service_class.constantize.new( BazaarCore.wholesale_tax_service_config )

			@transaction_service	= args[:transaction_service]
			@transaction_service	||= BazaarCore.wholesale_transaction_service_class.constantize.new( BazaarCore.wholesale_transaction_service_config )

			@discount_service		= args[:discount_service]
			@discount_service		||= BazaarCore.wholesale_discount_service_class.constantize.new( BazaarCore.wholesale_discount_service_config )

		end
	end

end
