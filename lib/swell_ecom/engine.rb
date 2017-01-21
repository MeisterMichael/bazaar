
require 'stripe'
require 'tax_cloud'
require 'avalara'

module SwellEcom


	class << self
		mattr_accessor :origin_address

	end

	# this function maps the vars from your app into your engine
     def self.configure( &block )
        yield self
     end



  class Engine < ::Rails::Engine
    isolate_namespace SwellEcom
  end
end
