module Bazaar

	class ShippingService < ::ApplicationService

		def initialize( args = {} )
			@multiplier_adjustment = 1.00 + ( ( args[:percent_adjustment] || 0 ).to_f / 100.00 )
			@flat_adjustment = args[:flat_adjustment] || 0

			@code_whitelist = args[:code_whitelist]
			@code_blacklist = args[:code_blacklist]

			@labels = {}
			@labels = args[:name_whitelist] if args[:name_whitelist].is_a? Hash

			@name_whitelist = args[:name_whitelist].keys if args[:name_whitelist].is_a? Hash
			@name_whitelist = args[:name_whitelist] if args[:name_whitelist].is_a? Array

			@name_blacklist = args[:name_blacklist]


		end

		def calculate( obj, args = {} )
			return self.calculate_order( obj, args ) if obj.is_a? Order
			return self.calculate_cart( obj, args ) if obj.is_a? Cart
			return self.calculate_shipment( obj, args ) if obj.is_a? Shipment
		end

		def fetch_delivery_status( order, args = {} )
			shipment = order.shipments.where( tracking_code: order.tracking_number ).first

			fetch_delivery_status_for_code( order.tracking_number, args.merge( shipment: shipment ) )
		end

		def fetch_delivery_status_for_code( code, args = {} )
			# @todo
		end

		def find_rates( obj, args = {} )
			return self.find_order_rates( obj, args ) if obj.is_a? Order
			return self.find_cart_rates( obj, args ) if obj.is_a? Cart
			return self.find_subscription_rates( obj, args ) if obj.is_a? Subscription
			return self.find_shipment_rates( obj, args ) if obj.is_a? Shipment
		end

		def process( order, args = {} )
			# @todo
		end

		def process_shipment( shipment )
			shipment.processable_at = Time.now
			shipment.status = 'pending'
			shipment.save
		end

		def validate( geo_address )
			# @todo
			not( geo_address.errors.present? )
		end

		def calculate_cart( cart, args = {} )
			rates = find_cart_rates( cart, args )
			rate = find_default_rate( rates )

			if rate.present?
				cart.update( estimated_shipping: rate[:price] )
			else
				cart.update( estimated_shipping: 0 )
			end
		end

		def calculate_order( order, args={} )
			initialize_order_shipments( order, args )

			order.shipping = 0
			return false if order.shipping_user_address.nil?
			return false if not( order.shipping_user_address.validate ) || order.shipping_user_address.geo_country.blank? || order.shipping_user_address.zip.blank?

			order.shipments.to_a.select(&:not_negative_status?).each do |shipment|
				calculate_shipment( shipment, args )

				rate = shipment.rates.find{ |rate| rate[:selected] }

				if rate.present?
					shipping_order_item = order.order_items.new( item: rate[:carrier_service], price: rate[:price], subtotal: rate[:price], title: (rate[:label] || rate[:name]), order_item_type: 'shipping', tax_code: '11000', properties: { 'name' => rate[:name], 'code' => rate[:code], 'carrier' => rate[:carrier] } )
					order.shipping += rate[:price]
				end
			end

			return true

		end

		def calculate_shipment( shipment, args = {} )
			shipment.rates = []
			shipment.shipping_carrier_service = nil
			shipment.carrier_service_level = nil
			shipment.price = nil
			shipment.cost = nil

			rates = find_shipment_rates( shipment, args )
			rates.each do |rate|
				rate[:shipment] = shipment
			end
			sorted_rates = rates.sort_by{ |rate| rate[:cost] }

			if args[:rate_code].present?
				rate = sorted_rates.select{ |rate| rate[:carrier_service].service_code == args[:rate_code] }.first
			elsif args[:rate_name].present?
				rate = sorted_rates.select{ |rate| rate[:carrier_service].service_name == args[:rate_name] }.first
			elsif args[:shipping_carrier_service_id].present?
				rate = sorted_rates.select{ |rate| rate[:carrier_service].id == args[:shipping_carrier_service_id].to_i }.first
			end

			rate ||= find_default_rate( sorted_rates )

			rate[:selected] = true if rate

			shipment.rates = rates

			if rate.present?

				if rate[:carrier_service].is_a? Bazaar::ShippingCarrierService
					shipment.shipping_carrier_service = rate[:carrier_service]
					shipment.carrier_service_level = rate[:carrier_service].service_name
				end

				shipment.price = rate[:price]
				shipment.cost = rate[:cost]

			end

			return { success: true, rates: rates }
		end

		def find_cart_rates( cart, args = {} )
			return [] unless args[:ip_country].present?
			country = GeoCountry.find_by( abbrev: args[:ip_country].upcase )
			return [] unless country.present?

			address = GeoAddress.new( geo_country: country )

			find_address_rates( address, cart.cart_offers, args )
		end

		def recalculate( obj, args = {} )
			return self.calculate_order( obj, args ) if obj.is_a? Order
			return self.calculate_cart( obj, args ) if obj.is_a? Cart
			return self.calculate_shipment( obj, args ) if obj.is_a? Shipment
		end

		protected

		def find_default_rate( rates )
			rate = rates.sort_by{ |rate| rate[:cost] }.first
		end

		def find_order_rates( order, args = {} )
			find_address_rates( order.shipping_user_address, order.order_offers.select{ |order_offer| order_offer.quantity > 0 }, args )
		end

		def find_shipment_rates( shipment, args = {} )
			# @todo update order rate calculation to shipments rather than order
			# find_order_rates( shipment.order, args )
			find_address_rates( shipment.destination_user_address, shipment.shipment_skus.collect{ |shipment_sku| OrderItem.new( item: shipment_sku.sku, quantity: shipment_sku.quantity ) }, args )
		end

		def find_subscription_rates( subscription, args = {} )
			find_address_rates( subscription.shipping_user_address, [OrderOffer.new( subscription: subscription, offer: subscription.offer, subscription_interval: subscription.next_subscription_interval, quantity: subscription.quantity )], args )
		end

		def find_address_rates( geo_address, line_items, args = {} )
			cache_key = geo_address.attributes.to_json
			cache_key = cache_key + line_items.collect(&:attributes).to_json

			cached_rates = Rails.cache.fetch("bazaar/shipping_service/#{cache_key}", expires_in: 10.minutes) do

				request_rates = request_address_rates( geo_address, line_items, args )

				request_rates.collect do |rate|
					carrier_service = Bazaar::ShippingCarrierService.create_with( name: rate[:name] ).find_or_create_by( service_name: rate[:name], service_code: rate[:code], carrier: rate[:carrier] )
				end

				request_rates = request_rates.select{ |rate| @code_whitelist.include?( rate[:code] ) } if @code_whitelist.present?
				request_rates = request_rates.select{ |rate| not( @code_blacklist.include?( rate[:code] ) ) } if @code_blacklist.present?
				request_rates = request_rates.select{ |rate| @name_whitelist.include?( rate[:name] ) } if @name_whitelist.present?
				request_rates = request_rates.select{ |rate| not( @name_blacklist.include?( rate[:name] ) ) } if @name_blacklist.present?

				rates = []
				request_rates.collect do |rate|
					carrier_service = Bazaar::ShippingCarrierService.create_with( name: rate[:name] ).find_or_create_by( service_name: rate[:name], service_code: rate[:code], carrier: rate[:carrier] )

					price = (rate[:price] * @multiplier_adjustment + @flat_adjustment).round()
					label = carrier_service.shipping_option.try(:name) || @labels[rate[:name]] || rate[:name]

					rates << { price: price, cost: rate[:price], label: label, id: carrier_service.id, carrier_service: carrier_service } # @todo if carrier_service.active? && carrier_service.shipping_option.try(:active?)
				end

				rates

	    end

			unless ( fixed_price = args[:fixed_price] ).nil?

				cached_rates.each do |rate|
					rate[:price] = fixed_price
				end

			end

			cached_rates
		end

		def initialize_order_shipments( order, args = {} )

			shipment = order.shipments.first
			shipment ||= order.shipments.new(
				destination_address: order.shipping_address,
				destination_user_address: order.shipping_user_address,
				status: 'draft',
			)

			order.order_skus.each do |order_sku|
				shipment_sku = shipment.shipment_skus.to_a.select{|shipment_sku| shipment_sku.sku == order_sku.sku }
				shipment_sku ||= shipment.shipment_skus.new( sku: order_sku.sku )
				shipment_sku.quantity = order_sku.quantity
			end

		end

		def request_address_rates( geo_address, line_items, args = {} )
			[]
		end

	end

end
