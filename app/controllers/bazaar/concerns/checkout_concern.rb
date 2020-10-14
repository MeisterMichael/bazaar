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
						:phone,
						:customer_notes,
						:same_as_billing,
						:same_as_shipping,
						{
							:order_offers => [
								:offer_id,
								:quantity,
							],
							:billing_user_address_attributes => [
								:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name,
							],
							:shipping_user_address_attributes => [
								:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name,
							],
							:order_offers_attributes => [
								:offer_id,
								:quantity,
							],
						},
					]
				).to_h

				order_attributes = order_attributes[:order] || {}

				order_attributes[:billing_user_address_attributes]	= order_attributes[:billing_user_address_attributes] || order_attributes.delete(:billing_address_attributes) || order_attributes.delete(:billing_address) || order_attributes.delete(:billing_user_address) || {}
				order_attributes[:shipping_user_address_attributes]	= order_attributes[:shipping_user_address_attributes] || order_attributes.delete(:shipping_address_attributes) || order_attributes.delete(:shipping_address) || order_attributes.delete(:shipping_user_address) || {}

				order_attributes[:billing_user_address_attributes]	= order_attributes[:shipping_user_address_attributes] if order_attributes.delete(:same_as_shipping)
				order_attributes[:shipping_user_address_attributes]	= order_attributes[:billing_user_address_attributes] if order_attributes.delete(:same_as_billing)

				order_attributes[:billing_user_address_attributes] ||= {}
				order_attributes[:shipping_user_address_attributes] ||= {}


				order_attributes[:billing_user_address_attributes][:phone]	||= order_attributes[:phone]
				order_attributes[:shipping_user_address_attributes][:phone]	||= order_attributes[:phone]

				order_attributes[:order_offers_attributes]		||= order_attributes.delete(:order_offers) || []

				# order_attributes[:billing_user_address_attributes]	= order_attributes[:billing_user_address_attributes] || order_attributes.delete(:billing_address_attributes) || order_attributes.delete(:billing_address) || order_attributes.delete(:billing_user_address) || {}
				# order_attributes[:shipping_user_address_attributes]	= order_attributes[:shipping_user_address_attributes] || order_attributes.delete(:shipping_address_attributes) || order_attributes.delete(:shipping_address) || order_attributes.delete(:shipping_user_address) || {}
				# order_attributes[:billing_user_address_attributes]	= order_attributes[:shipping_user_address_attributes] if order_attributes.delete(:same_as_shipping)
				# order_attributes[:shipping_user_address_attributes]	= order_attributes[:billing_user_address_attributes] if order_attributes.delete(:same_as_billing)
				# order_attributes[:billing_user_address_attributes] ||= {}
				# order_attributes[:shipping_user_address_attributes] ||= {}
				# order_attributes[:order_offers_attributes]		||= order_attributes.delete(:order_offers) || []

				if order_attributes[:order_offers_attributes].present?
					order_offer_attributes = order_attributes[:order_offers_attributes]
					order_offer_attributes = order_offer_attributes.values if order_offer_attributes.is_a? Hash

					order_offer_attributes.each do |order_offer|
						order_offer[:offer]				= Bazaar::Offer.find_by( id: order_offer[:offer_id] )
						order_offer[:title]				= order_offer[:offer].title
						order_offer[:price]				= order_offer[:offer].initial_price
						order_offer[:subtotal]		= order_offer[:price].to_i * order_offer[:quantity].to_i
						order_offer[:tax_code]		= order_offer[:item].tax_code
					end
				end

				order_attributes[:status]	||= 'active'
				order_attributes[:ip]		||= client_ip
				order_attributes[:currency]	||= 'usd'

				order_attributes

			end

			def initialize_services
				@fraud_service = BazaarCore.fraud_service_class.constantize.new( BazaarCore.fraud_service_config.merge( params: params, session: session, cookies: cookies, request: request ) )
				@order_service = BazaarCore.checkout_order_service_class.constantize.new( fraud_service: @fraud_service )
				@upsell_service = BazaarCore.upsell_service_class.constantize.new
			end

			def discount_options_params
				(params.permit( :discount_options => [ :code ] )[:discount_options] || {}).to_h
			end

			def order_options_params
				(params.permit( :order_options => BazaarCore.permit_order_options || [] )[:order_options] || {}).to_h
			end

			def shipping_options_params
				(params.permit( :shipping_options => [ :rate_code, :rate_name, :shipping_carrier_service_id ] )[:shipping_options] || {}).to_h
			end

			def transaction_options_params
				(params.permit( :transaction_options => [ :options, :service, :stripeToken, :credit_card => [ :card_number, :expiration, :card_code ], :pay_pal => [ :payment_id, :payer_id, :order_id, :payment_token ] ] )[:transaction_options] || {}).to_h
			end

			def discount_options
				discount_options_params.merge({ ip: client_ip, ip_country: client_ip_country })
			end

			def order_options
				order_options_params
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
