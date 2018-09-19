
Bazaar.configure do |config|

	config.origin_address = {
		street: '1412 Camino Del Mar',
		city: 'SAN DIEGO',
		state: 'CA',
		zip: '92014',
		country: 'US',
	}

	config.order_email_from = "no-reply@#{ENV['APP_DOMAIN']}"

	config.transaction_service_class = "Bazaar::TransactionServices::AuthorizeDotNetTransactionService"
	# config.transaction_service_config = {}

	# config.shipping_service_class = "Bazaar::ShippingService"
	# config.shipping_service_config = {}

	# config.tax_service_class = "Bazaar::TaxService"
	# config.tax_service_config = {}

	config.nexus_addresses = [
		{
			street: '1412 Camino Del Mar',
			city: 'SAN DIEGO',
			state: 'CA',
			zip: '92014',
			country: 'US',
		},
	]


end
