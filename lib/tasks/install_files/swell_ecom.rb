
SwellEcom.configure do |config|

	config.origin_address = {
		street: '1412 Camino Del Mar',
		city: 'SAN DIEGO',
		state: 'CA',
		zip: '92014'
	}

	config.order_email_from = "no-reply@#{ENV['APP_DOMAIN']}"

end
