
require 'stripe'
require 'tax_cloud'

module SwellEcom


	class << self
		mattr_accessor :origin_address
		mattr_accessor :order_email_from
		mattr_accessor :billing_countries
		mattr_accessor :shipping_countries

		mattr_accessor :transaction_service_class
		mattr_accessor :transaction_service_config

		mattr_accessor :shipping_service_class
		mattr_accessor :shipping_service_config

		mattr_accessor :tax_service_class
		mattr_accessor :tax_service_config

		self.transaction_service_class = "SwellEcom::TransactionServices::StripeTransactionService"
		self.transaction_service_config = {}

		self.shipping_service_class = "SwellEcom::ShippingService"
		self.shipping_service_config = {}

		self.tax_service_class = "SwellEcom::TaxService"
		self.tax_service_config = {}

		self.order_email_from = "no-reply@#{ENV['APP_DOMAIN']}"
		self.billing_countries = { only: 'US' }
		self.shipping_countries = { only: 'US' }
	end

	# this function maps the vars from your app into your engine
     def self.configure( &block )
        yield self
     end



  class Engine < ::Rails::Engine
    isolate_namespace SwellEcom
  end
end
