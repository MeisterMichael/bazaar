
# require 'stripe'
# require 'tax_cloud'

module Bazaar


	class << self
		mattr_accessor :origin_address
		mattr_accessor :warehouse_address
		mattr_accessor :nexus_addresses
		mattr_accessor :order_email_from

		mattr_accessor :checkout_order_class_name

		mattr_accessor :discount_service_class
		mattr_accessor :discount_service_config

		mattr_accessor :enable_wholesale_order_mailer
		mattr_accessor :enable_checkout_order_mailer

		mattr_accessor :fraud_service_class
		mattr_accessor :fraud_service_config

		mattr_accessor :shipping_service_class
		mattr_accessor :shipping_service_config

		mattr_accessor :subscription_service_class
		mattr_accessor :subscription_service_config

		mattr_accessor :tax_service_class
		mattr_accessor :tax_service_config

		mattr_accessor :transaction_service_class
		mattr_accessor :transaction_service_config

		mattr_accessor :wholesale_item_collections

		mattr_accessor :wholesale_order_class_name

		mattr_accessor :wholesale_discount_service_class
		mattr_accessor :wholesale_discount_service_config

		mattr_accessor :wholesale_shipping_service_class
		mattr_accessor :wholesale_shipping_service_config

		mattr_accessor :wholesale_tax_service_class
		mattr_accessor :wholesale_tax_service_config

		mattr_accessor :wholesale_transaction_service_class
		mattr_accessor :wholesale_transaction_service_config

		mattr_accessor :checkout_order_service_class
		mattr_accessor :wholesale_order_service_class

		mattr_accessor :order_code_prefix
		mattr_accessor :order_code_postfix

		mattr_accessor :subscription_code_prefix
		mattr_accessor :subscription_code_postfix

		mattr_accessor :automated_fulfillment

		mattr_accessor :store_path

		mattr_accessor :create_user_on_checkout

		self.discount_service_class = "Bazaar::DiscountService"
		self.discount_service_config = {}

		self.enable_wholesale_order_mailer = true
		self.enable_checkout_order_mailer = true

		self.fraud_service_class = "Bazaar::FraudService"
		self.fraud_service_config = {}

		self.shipping_service_class = "Bazaar::ShippingService"
		self.shipping_service_config = {}

		self.subscription_service_class = "Bazaar::SubscriptionService"
		self.subscription_service_config = {}

		self.tax_service_class = "Bazaar::TaxService"
		self.tax_service_config = {}

		self.transaction_service_class = "Bazaar::TransactionServices::StripeTransactionService"
		self.transaction_service_config = {}


		self.wholesale_discount_service_class = "Bazaar::DiscountService"
		self.wholesale_discount_service_config = {}

		self.wholesale_shipping_service_class = "Bazaar::ShippingService"
		self.wholesale_shipping_service_config = {}

		self.wholesale_tax_service_class = "Bazaar::TaxService"
		self.wholesale_tax_service_config = {}

		self.wholesale_transaction_service_class = "Bazaar::TransactionServices::StripeTransactionService"
		self.wholesale_transaction_service_config = {}

		self.checkout_order_service_class = "Bazaar::CheckoutOrderService"
		self.wholesale_order_service_class = "Bazaar::WholesaleOrderService"

		self.warehouse_address = {}
		self.nexus_addresses = []

		self.order_email_from = "no-reply@#{ENV['APP_DOMAIN']}"

		self.checkout_order_class_name = "Bazaar::CheckoutOrder"
		self.wholesale_order_class_name = "Bazaar::WholesaleOrder"
		self.wholesale_item_collections = [ 'Bazaar::Product.published.active' ]

		self.order_code_prefix = nil
		self.order_code_postfix = nil

		self.subscription_code_prefix = nil
		self.subscription_code_postfix = nil

		self.automated_fulfillment = false

		self.store_path = 'store'

		self.create_user_on_checkout = false
	end

	# this function maps the vars from your app into your engine
     def self.configure( &block )
        yield self
     end



  class Engine < ::Rails::Engine
    isolate_namespace Bazaar
	config.generators do |g|
		g.test_framework :rspec, :fixture => false
		g.fixture_replacement :factory_girl, :dir => 'spec/factories'
		g.assets false
		g.helper false
	end
  end
end
