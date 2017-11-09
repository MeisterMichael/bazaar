
SwellEcom.configure do |config|

	config.origin_address = {
		street: '1412 Camino Del Mar',
		city: 'SAN DIEGO',
		state: 'CA',
		zip: '92014'
	}

	config.order_email_from = "no-reply@#{ENV['APP_DOMAIN']}"

	# config.transaction_service_class = "SwellEcom::TransactionServices::StripeTransactionService"
	# config.transaction_service_config = {}

	# config.shipping_service_class = "SwellEcom::ShippingService"
	# config.shipping_service_config = {}

	# config.tax_service_class = "SwellEcom::TaxService"
	# config.tax_service_config = {}


end
