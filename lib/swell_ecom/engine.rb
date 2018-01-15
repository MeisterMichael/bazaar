
require 'stripe'
require 'tax_cloud'

module SwellEcom


	class << self
		mattr_accessor :origin_address
		mattr_accessor :warehouse_address
		mattr_accessor :nexus_address
		mattr_accessor :order_email_from
		mattr_accessor :billing_countries
		mattr_accessor :shipping_countries

		mattr_accessor :discount_service_class
		mattr_accessor :discount_service_config

		mattr_accessor :shipping_service_class
		mattr_accessor :shipping_service_config

		mattr_accessor :tax_service_class
		mattr_accessor :tax_service_config

		mattr_accessor :transaction_service_class
		mattr_accessor :transaction_service_config

		self.transaction_service_class = "SwellEcom::TransactionServices::StripeTransactionService"
		self.transaction_service_config = {}

		self.shipping_service_class = "SwellEcom::ShippingService"
		self.shipping_service_config = {}

		self.tax_service_class = "SwellEcom::TaxService"
		self.tax_service_config = {}

		self.warehouse_address = {}
		self.nexus_address = {}

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
	config.generators do |g|
		g.test_framework :rspec, :fixture => false
		g.fixture_replacement :factory_girl, :dir => 'spec/factories'
		g.assets false
		g.helper false
	end
  end
end
