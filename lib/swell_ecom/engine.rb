
require 'stripe'
require 'tax_cloud'

module SwellEcom


	class << self
		mattr_accessor :origin_address
		mattr_accessor :order_email_from

		self.order_email_from = "no-reply@#{ENV['APP_DOMAIN']}"
	end

	# this function maps the vars from your app into your engine
     def self.configure( &block )
        yield self
     end



  class Engine < ::Rails::Engine
    isolate_namespace SwellEcom
  end
end
