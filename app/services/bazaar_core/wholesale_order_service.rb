module Bazaar

	class WholesaleOrderService < Bazaar::OrderService
		# abstract

		def initialize( args = {} )

			@fraud_service		= args[:fraud_service]
			@fraud_service		||= Bazaar.fraud_service_class.constantize.new( Bazaar.fraud_service_config )

			@shipping_service		= args[:shipping_service]
			@shipping_service		||= Bazaar.wholesale_shipping_service_class.constantize.new( Bazaar.wholesale_shipping_service_config )

			@tax_service			= args[:tax_service]
			@tax_service			||= Bazaar.wholesale_tax_service_class.constantize.new( Bazaar.wholesale_tax_service_config )

			@transaction_service	= args[:transaction_service]
			@transaction_service	||= Bazaar.wholesale_transaction_service_class.constantize.new( Bazaar.wholesale_transaction_service_config )

			@discount_service		= args[:discount_service]
			@discount_service		||= Bazaar.wholesale_discount_service_class.constantize.new( Bazaar.wholesale_discount_service_config )

		end
	end

end
