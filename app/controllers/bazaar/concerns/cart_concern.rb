module Bazaar
	module Concerns

		module CartConcern
			extend ActiveSupport::Concern

			included do
				include Bazaar::ApplicationHelper
			end


			####################################################
			# Class Methods

			module ClassMethods

			end


			####################################################
			# Instance Methods


			protected

			def update_bazaar_cart( options = {} )

				@cart.attributes = options[:attributes] if options[:attributes].present?
				@cart.properties = @cart.properties.merge(options[:properties]) if options[:properties].present?

				@cart.save
			end

			def clear_bazaar_cart
				session[:cart_count] = 0
				session[:cart_id] = nil
			end

			def create_bazaar_cart( options = {} )
				@cart = Cart.new( ip: client_ip )
				update_bazaar_cart( options )
				session[:cart_id] = @cart.id
				@cart
			end

			def get_bazaar_cart( options = {} )
				@cart ||= Bazaar::Cart.find_by( id: session[:cart_id] )
				update_bazaar_cart( options ) if @cart.present?
			end

			def get_or_create_bazaar_cart( options = {} )
				get_bazaar_cart( options )
				create_bazaar_cart( options ) unless @cart.present?
			end

		end

	end
end
