
Bazaar.configure do |config|

	config.origin_address = {
		street: '1412 Camino Del Mar',
		city: 'SAN DIEGO',
		state: 'CA',
		zip: '92014',
		country: 'US',
	}

	config.warehouse_address = {
		street: '1412 Camino Del Mar',
		city: 'SAN DIEGO',
		state: 'CA',
		zip: '92014',
		country: 'US',
	}

	config.nexus_addresses = [
		{
			street: '1412 Camino Del Mar',
			city: 'SAN DIEGO',
			state: 'CA',
			zip: '92014',
			country: 'US',
		},
	]

	config.order_email_from = "no-reply@#{ENV['APP_DOMAIN']}"

	# config.transaction_service_class = "::ApplicationTransactionService"
	# config.transaction_service_config = {}

	# config.shipping_service_class = "::ApplicationShippingService"
	# config.shipping_service_config = {}

	# config.tax_service_class = "::ApplicationTaxService"
	# config.tax_service_config = {}

	# config.discount_service_class = "::ApplicationDiscountService"
	# config.discount_service_config = {}

	# config.order_code_prefix = 'swell-o'
	# config.subscription_code_prefix = 'swell-s'

	# config.automated_fulfillment = true

	# config.create_user_on_checkout = true

	# config.store_path = 'shop'

end
