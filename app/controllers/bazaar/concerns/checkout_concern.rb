module Bazaar
	module Concerns

		module CheckoutConcern
			extend ActiveSupport::Concern

			def update_order_user_address( order )

				# if order user exists, update it's address info with the
				# billing address, if not already set
				if ( user = order.user ).present?
					user.update(
						address1: (order.user.address1 || order.billing_address.street),
						address2: (order.user.address2 || order.billing_address.street2),
						city: (order.user.city || order.billing_address.city),
						state: (order.user.state || order.billing_address.state_abbrev),
						zip: (order.user.zip || order.billing_address.zip),
						phone: (order.user.phone || order.billing_address.phone),
						preferred_billing_address_id: (user.preferred_billing_address_id || order.billing_address.id),
						preferred_shipping_address_id: (user.preferred_shipping_address_id || order.shipping_address.id),
					)
				end

			end

			def get_order_attributes
				order_attributes = params.permit(
					order: [
						:email,
						:customer_notes,
						:same_as_billing,
						:same_as_shipping,
						{
							:billing_address => [
								:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name,
							],
							:shipping_address => [
								:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name,
							],
							:order_items => [
								:item_type,
								:item_id,
								:quantity,
							],
							:billing_address_attributes => [
								:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name,
							],
							:shipping_address_attributes => [
								:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name,
							],
							:order_items_attributes => [
								:item_type,
								:item_id,
								:quantity,
							],
						},
					]
				).to_h

				order_attributes = order_attributes[:order] || {}

				order_attributes[:billing_address_attributes]	||= order_attributes.delete(:billing_address) || {}
				order_attributes[:shipping_address_attributes]	||= order_attributes.delete(:shipping_address) || {}
				order_attributes[:order_items_attributes]		||= order_attributes.delete(:order_items) || []

				order_attributes[:shipping_address_attributes]	= order_attributes[:billing_address_attributes] if order_attributes.delete(:same_as_billing)
				order_attributes[:billing_address_attributes]	= order_attributes[:shipping_address_attributes] if order_attributes.delete(:same_as_shipping)

				if order_attributes[:order_items_attributes].present?
					order_item_attributes = order_attributes[:order_items_attributes]
					order_item_attributes = order_item_attributes.values if order_item_attributes.is_a? Hash

					order_item_attributes.each do |order_item|
						order_item[:order_item_type] 	= 'prod'
						order_item[:item]				= order_item[:item_type].constantize.find_by( id: order_item[:item_id] )
						order_item[:title]				= order_item[:item].title
						order_item[:price]				= order_item[:item].price
						order_item[:price]				= order_item[:item].trial_price if order_item[:item].is_a?( SubscriptionPlan ) && order_item[:item].trial?
						order_item[:subtotal]			= order_item[:price].to_i * order_item[:quantity].to_i
						order_item[:tax_code]			= order_item[:item].tax_code
					end
				end

				order_attributes[:status]	||= 'active'
				order_attributes[:ip]		||= client_ip
				order_attributes[:currency]	||= 'usd'

				order_attributes

			end

			def initialize_services
				@fraud_service = Bazaar.fraud_service_class.constantize.new( Bazaar.fraud_service_config.merge( params: params, session: session, cookies: cookies, request: request ) )
				@order_service = Bazaar::OrderService.new( fraud_service: @fraud_service )
			end

			def discount_options_params
				(params.permit( :discount_options => [ :code ] )[:discount_options] || {}).to_h
			end

			def shipping_options_params
				(params.permit( :shipping_options => [ :rate_code, :rate_name, :shipping_carrier_service_id ] )[:shipping_options] || {}).to_h
			end

			def transaction_options_params
				(params.permit( :transaction_options => [ :service, :stripeToken, :credit_card => [ :card_number, :expiration, :card_code ], :pay_pal => [ :payment_id, :payer_id ] ] )[:transaction_options] || {}).to_h
			end

			def discount_options
				discount_options_params.merge({ ip: client_ip, ip_country: client_ip_country })
			end

			def shipping_options
				shipping_options_params.merge({ ip: client_ip, ip_country: client_ip_country })
			end

			def transaction_options
				transaction_options_params.merge({ ip: client_ip, ip_country: client_ip_country })
			end

		end
	end
end
