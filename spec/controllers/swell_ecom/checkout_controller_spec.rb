require "spec_helper"
# Currently assumes rake db:seed

RSpec.describe SwellEcom::CheckoutController, :type => :controller do
	render_views
	routes { SwellEcom::Engine.routes }

	let(:new_trial_subscription_plan) {
		SwellEcom::SubscriptionPlan.create( slug: "subscription-plan-1-#{(0...20).map { (65 + rand(26)).chr }.join}", title: "Subscription w/ Trial", trial_price: 99, trial_max_intervals: 1, price: 12900, billing_interval_unit: 'weeks', billing_interval_value: 4, trial_interval_unit: 'days', trial_interval_value: 7 )
	}
	let(:new_trial_subscription_plan2) {
		SwellEcom::SubscriptionPlan.create( slug: "subscription-plan-2-#{(0...20).map { (65 + rand(26)).chr }.join}", title: "Subscription w/ Trial 199", trial_price: 199, trial_max_intervals: 1, price: 14900, billing_interval_unit: 'weeks', billing_interval_value: 2, trial_interval_unit: 'days', trial_interval_value: 3 )
	}
	let(:new_pre_order_product) {
		SwellEcom::Product.create( slug: "pre-order-product-#{(0...20).map { (65 + rand(26)).chr }.join}", title: "Pre Order", price: 13900, availability: 'pre_order' )
	}

	let(:new_active_product) {
		SwellEcom::Product.create( slug: "pre-order-product-#{(0...20).map { (65 + rand(26)).chr }.join}", title: "Pre Order", price: 15900, availability: 'open_availability' )
	}

	describe "POST create" do

		it "subscription - success" do
			time_now = Time.now

			usa = SwellEcom::GeoCountry.create :abbrev => "US", :name => "United States"
			ark = usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Arkansas', :abbrev => 'AR'
			cali = usa.geo_states.create :country => 'US', geo_country: usa, :name => 'California', :abbrev => 'CA'
			subscription_plan = new_trial_subscription_plan

			user = User.create( first_name: "Michael", last_name: (0...8).map { (65 + rand(26)).chr }.join, email: "#{(0...20).map { (65 + rand(26)).chr }.join}@groundswellent.com" )

			cart = SwellEcom::Cart.create
			cart.cart_items.create( item_type: subscription_plan.class.name, item_id: subscription_plan.id, quantity: 1, price: subscription_plan.trial_price, subtotal: subscription_plan.trial_price )

			allow(request.env['warden']).to receive(:authenticate!).and_return(user)
			allow(controller).to receive(:current_user).and_return(user)
			allow(controller).to receive(:current_user).and_return(user)

			billing_address = shipping_address = {
				phone: '8583531111',
				zip: '92126',
				geo_country_id: usa.id,
				geo_state_id: cali.id,
				# state: 'CA',
				city: 'San Diego',
				street2: nil,
				street: '2120 Jimmy Durante Blvd',
				last_name: user.last_name,
				first_name: user.first_name,
			}

			order = {
				email: user.email,
				customer_notes: '',
				billing_address: billing_address,
				shipping_address: shipping_address,
			}

			expiration_time = (Time.now + 1.year).end_of_year
			expiration_year = expiration_time.strftime('%y')
			expiration_month = expiration_time.month.to_s

			credit_card = {
				expiration: expiration_month+'/'+expiration_year,
				card_number: '4111111111111111',
				card_code: '123',
			}

			same_as_billing = nil



			post :create, params: { format: :json, order: order, transaction_options: { credit_card: credit_card }, same_as_billing: same_as_billing }, session: { cart_id: cart.id }
			expect(response).to render_template(:create)
			expect(response.content_type).to eq "application/json"
			expect(response.status).to eq(200)

			body_json = JSON.parse response.body
			expect(body_json['success']).to eq(true)
			expect(body_json['errors'].blank?).to eq(true)
			expect(body_json['order_code'].present?).to eq(true)
			expect(body_json['email']).to eq(order[:email])
			expect(body_json['billing_address_first_name']).to eq( billing_address[:first_name] )
			expect(body_json['billing_address_last_name']).to eq( billing_address[:last_name] )
			expect(body_json['billing_address_street']).to eq( billing_address[:street] )
			expect(body_json['billing_address_street2'] || '').to eq( billing_address[:street2] || '' )
			expect(body_json['billing_address_city']).to eq( billing_address[:city] )
			expect(body_json['billing_address_state']).to eq( cali.abbrev )
			expect(body_json['billing_address_zip']).to eq( billing_address[:zip] )
			expect(body_json['shipping_address_first_name']).to eq( shipping_address[:first_name] )
			expect(body_json['shipping_address_last_name']).to eq( shipping_address[:last_name] )
			expect(body_json['shipping_address_street']).to eq( shipping_address[:street] )
			expect(body_json['shipping_address_street2'] || '').to eq( shipping_address[:street2] || '' )
			expect(body_json['shipping_address_city']).to eq( shipping_address[:city] )
			expect(body_json['shipping_address_state']).to eq( cali.abbrev )
			expect(body_json['shipping_address_zip']).to eq( shipping_address[:zip] )

			new_cart = SwellEcom::Cart.find( cart.id )
			expect( new_cart.present? ).to eq(true)
			expect( new_cart.status ).to eq('success')

			order = SwellEcom::CheckoutOrder.find_by( code: body_json['order_code'] )
			expect(order.class).to eq( SwellEcom::CheckoutOrder )
			expect( order.code ).to eq( body_json['order_code'] )
			expect( order.payment_status ).to eq( 'paid' )
			expect( order.fulfillment_status ).to eq( 'unfulfilled' )
			expect( order.order_items.prod.count ).to eq( 1 )


			subscription = order.order_items.prod.first.subscription
			expect( subscription.class ).to eq( SwellEcom::Subscription )
			expect( subscription.status ).to eq( 'active' )
			expect( subscription.provider.blank? ).to eq( false )
			expect( subscription.provider_customer_profile_reference.blank? ).to eq( false )
			expect( subscription.provider_customer_payment_profile_reference.blank? ).to eq( false )
			expect( subscription.user ).to eq( user )
			expect( subscription.subscription_plan.present? ).to eq( true )
			expect( subscription.billing_address.present? ).to eq( true )
			expect( subscription.shipping_address.present? ).to eq( true )
			expect( subscription.trial_amount ).to eq( 99 )
			expect( subscription.amount ).to eq( 12900 )
			expect( subscription.currency ).to eq( 'usd' )

		end

		it "active product - success" do
			time_now = Time.now

			usa = SwellEcom::GeoCountry.create :abbrev => "US", :name => "United States"
			ark = usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Arkansas', :abbrev => 'AR'
			cali = usa.geo_states.create :country => 'US', geo_country: usa, :name => 'California', :abbrev => 'CA'
			product = new_active_product

			user = User.create( first_name: "Michael", last_name: (0...8).map { (65 + rand(26)).chr }.join, email: "#{(0...20).map { (65 + rand(26)).chr }.join}@groundswellent.com" )

			cart = SwellEcom::Cart.create
			cart.cart_items.create( item_type: product.class.name, item_id: product.id, quantity: 2, price: product.price, subtotal: product.price * 2 )

			allow(request.env['warden']).to receive(:authenticate!).and_return(user)
			allow(controller).to receive(:current_user).and_return(user)
			allow(controller).to receive(:current_user).and_return(user)

			billing_address = shipping_address = {
				phone: '8583531111',
				zip: '92126',
				geo_country_id: usa.id,
				geo_state_id: cali.id,
				# state: 'CA',
				city: 'San Diego',
				street2: nil,
				street: '2120 Jimmy Durante Blvd',
				last_name: user.last_name,
				first_name: user.first_name,
			}

			order = {
				email: user.email,
				customer_notes: '',
				billing_address: billing_address,
				shipping_address: shipping_address,
			}

			expiration_time = (Time.now + 1.year).end_of_year
			expiration_year = expiration_time.strftime('%y')
			expiration_month = expiration_time.month.to_s

			credit_card = {
				expiration: expiration_month+'/'+expiration_year,
				card_number: '4111111111111111',
				card_code: '123',
			}

			same_as_billing = nil



			post :create, params: { format: :json, order: order, transaction_options: { credit_card: credit_card }, same_as_billing: same_as_billing }, session: { cart_id: cart.id }
			expect(response).to render_template(:create)
			expect(response.content_type).to eq "application/json"
			expect(response.status).to eq(200)

			body_json = JSON.parse response.body
			expect(body_json['success']).to eq(true)
			expect(body_json['errors'].blank?).to eq(true)
			expect(body_json['order_code'].present?).to eq(true)
			expect(body_json['email']).to eq(order[:email])
			expect(body_json['billing_address_first_name']).to eq( billing_address[:first_name] )
			expect(body_json['billing_address_last_name']).to eq( billing_address[:last_name] )
			expect(body_json['billing_address_street']).to eq( billing_address[:street] )
			expect(body_json['billing_address_street2'] || '').to eq( billing_address[:street2] || '' )
			expect(body_json['billing_address_city']).to eq( billing_address[:city] )
			expect(body_json['billing_address_state']).to eq( cali.abbrev )
			expect(body_json['billing_address_zip']).to eq( billing_address[:zip] )
			expect(body_json['shipping_address_first_name']).to eq( shipping_address[:first_name] )
			expect(body_json['shipping_address_last_name']).to eq( shipping_address[:last_name] )
			expect(body_json['shipping_address_street']).to eq( shipping_address[:street] )
			expect(body_json['shipping_address_street2'] || '').to eq( shipping_address[:street2] || '' )
			expect(body_json['shipping_address_city']).to eq( shipping_address[:city] )
			expect(body_json['shipping_address_state']).to eq( cali.abbrev )
			expect(body_json['shipping_address_zip']).to eq( shipping_address[:zip] )

			new_cart = SwellEcom::Cart.find( cart.id )
			expect( new_cart.present? ).to eq(true)
			expect( new_cart.status ).to eq('success')

			order = SwellEcom::CheckoutOrder.find_by( code: body_json['order_code'] )
			expect(order.class).to eq( SwellEcom::CheckoutOrder )
			expect( order.status ).to eq( 'active' )
			expect( order.code ).to eq( body_json['order_code'] )
			expect( order.payment_status ).to eq( 'paid' )
			expect( order.fulfillment_status ).to eq( 'unfulfilled' )
			expect( order.order_items.prod.count ).to eq( 1 )
			expect( order.total ).to eq( 31800 )
			expect( order.transactions.approved.charge.sum(:amount) ).to eq( order.total )

		end

		it "pre_order - success" do
			time_now = Time.now

			usa = SwellEcom::GeoCountry.create :abbrev => "US", :name => "United States"
			ark = usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Arkansas', :abbrev => 'AR'
			cali = usa.geo_states.create :country => 'US', geo_country: usa, :name => 'California', :abbrev => 'CA'
			product = new_pre_order_product

			user = User.create( first_name: "Michael", last_name: (0...8).map { (65 + rand(26)).chr }.join, email: "#{(0...20).map { (65 + rand(26)).chr }.join}@groundswellent.com" )

			cart = SwellEcom::Cart.create
			cart.cart_items.create( item_type: product.class.name, item_id: product.id, quantity: 2, price: product.price, subtotal: product.price * 2 )

			allow(request.env['warden']).to receive(:authenticate!).and_return(user)
			allow(controller).to receive(:current_user).and_return(user)
			allow(controller).to receive(:current_user).and_return(user)

			billing_address = shipping_address = {
				phone: '8583531111',
				zip: '92126',
				geo_country_id: usa.id,
				geo_state_id: cali.id,
				# state: 'CA',
				city: 'San Diego',
				street2: nil,
				street: '2120 Jimmy Durante Blvd',
				last_name: user.last_name,
				first_name: user.first_name,
			}

			order = {
				email: user.email,
				customer_notes: '',
				billing_address: billing_address,
				shipping_address: shipping_address,
			}

			expiration_time = (Time.now + 1.year).end_of_year
			expiration_year = expiration_time.strftime('%y')
			expiration_month = expiration_time.month.to_s

			credit_card = {
				expiration: expiration_month+'/'+expiration_year,
				card_number: '4111111111111111',
				card_code: '123',
			}

			same_as_billing = nil



			post :create, params: { format: :json, order: order, transaction_options: { credit_card: credit_card }, same_as_billing: same_as_billing }, session: { cart_id: cart.id }
			expect(response).to render_template(:create)
			expect(response.content_type).to eq "application/json"
			expect(response.status).to eq(200)

			body_json = JSON.parse response.body
			expect(body_json['success']).to eq(true)
			expect(body_json['errors'].blank?).to eq(true)
			expect(body_json['order_code'].present?).to eq(true)
			expect(body_json['email']).to eq(order[:email])
			expect(body_json['billing_address_first_name']).to eq( billing_address[:first_name] )
			expect(body_json['billing_address_last_name']).to eq( billing_address[:last_name] )
			expect(body_json['billing_address_street']).to eq( billing_address[:street] )
			expect(body_json['billing_address_street2'] || '').to eq( billing_address[:street2] || '' )
			expect(body_json['billing_address_city']).to eq( billing_address[:city] )
			expect(body_json['billing_address_state']).to eq( cali.abbrev )
			expect(body_json['billing_address_zip']).to eq( billing_address[:zip] )
			expect(body_json['shipping_address_first_name']).to eq( shipping_address[:first_name] )
			expect(body_json['shipping_address_last_name']).to eq( shipping_address[:last_name] )
			expect(body_json['shipping_address_street']).to eq( shipping_address[:street] )
			expect(body_json['shipping_address_street2'] || '').to eq( shipping_address[:street2] || '' )
			expect(body_json['shipping_address_city']).to eq( shipping_address[:city] )
			expect(body_json['shipping_address_state']).to eq( cali.abbrev )
			expect(body_json['shipping_address_zip']).to eq( shipping_address[:zip] )

			new_cart = SwellEcom::Cart.find( cart.id )
			expect( new_cart.present? ).to eq(true)
			expect( new_cart.status ).to eq('success')

			order = SwellEcom::CheckoutOrder.find_by( code: body_json['order_code'] )
			expect(order.class).to eq( SwellEcom::CheckoutOrder )
			expect( order.status ).to eq( 'pre_order' )
			expect( order.code ).to eq( body_json['order_code'] )
			expect( order.payment_status ).to eq( 'payment_method_captured' )
			expect( order.fulfillment_status ).to eq( 'unfulfilled' )
			expect( order.order_items.prod.count ).to eq( 1 )
			expect( order.total ).to eq( 27800 )
			expect( order.transactions.approved.charge.sum(:amount) ).to eq( 0 )

		end

	end

end
