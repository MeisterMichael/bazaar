require "spec_helper"

describe "TaxJarTaxService" do

	let(:user) { ::User.create( email: "#{(0...20).map { (65 + rand(26)).chr }.join}@groundswellent.com", first_name: 'Michael', last_name: (0...8).map { (65 + rand(26)).chr }.join ) }
	let(:address) { SwellEcom::GeoAddress.new( first_name: 'Michael', last_name: (0...8).map { (65 + rand(26)).chr }.join, zip: '92126', phone: "1#{(0...10).map { (rand(8)+1).to_s }.join}", city: 'San Diego', geo_country: SwellEcom::GeoCountry.new( name: 'United States', abbrev: 'US' ), geo_state: SwellEcom::GeoState.new( name: 'California', abbrev: 'CA' ) ) }
	let(:address2) { SwellEcom::GeoAddress.new( first_name: 'Michael', last_name: (0...8).map { (65 + rand(26)).chr }.join, zip: '37219', phone: "1#{(0...10).map { (rand(8)+1).to_s }.join}", city: 'nashville', geo_country: SwellEcom::GeoCountry.new( name: 'United States', abbrev: 'US' ), geo_state: SwellEcom::GeoState.new( name: 'Tennessee', abbrev: 'TN' ) ) }
	let(:address3) { SwellEcom::GeoAddress.new( first_name: 'Michael', last_name: (0...8).map { (65 + rand(26)).chr }.join, zip: '20317', phone: "1#{(0...10).map { (rand(8)+1).to_s }.join}", city: 'Washington', geo_country: SwellEcom::GeoCountry.new( name: 'United States', abbrev: 'US' ), geo_state: SwellEcom::GeoState.new( name: 'The District of Columbia', abbrev: 'DC' ) ) }
	let(:address4) { SwellEcom::GeoAddress.new( first_name: 'Michael', last_name: (0...8).map { (65 + rand(26)).chr }.join, zip: 'wc1n 3af', phone: "1#{(0...10).map { (rand(8)+1).to_s }.join}", city: 'London', geo_country: SwellEcom::GeoCountry.new( name: 'The United Kingdome', abbrev: 'UK' ), geo_state: SwellEcom::GeoState.new( name: 'London', abbrev: 'London' ) ) }
	let(:trial_subscription_plan) { SwellEcom::SubscriptionPlan.new( title: 'Test Trial Subscription Plan', trial_price: 99, price: 12900 ) }
	let(:subscription_plan) { SwellEcom::SubscriptionPlan.new( title: 'Test Subscription Plan', price: 12900 ) }
	let(:credit_card) { { card_number: '4111111111111111', expiration: '12/'+(Time.now + 1.year).strftime('%y'), card_code: '1234' } }
	let(:new_trial_subscription_plan_order) {
		order = SwellEcom::Order.new( billing_address: address, shipping_address: address, user: user )
		order.order_items.new item: trial_subscription_plan, price: trial_subscription_plan.trial_price, subtotal: trial_subscription_plan.trial_price, order_item_type: 'prod', quantity: 1, title: trial_subscription_plan.title, tax_code: trial_subscription_plan.tax_code
		order
	}
	let(:new_trial_subscription_plan_order2) {
		order = SwellEcom::Order.new( billing_address: address2, shipping_address: address2, user: user )
		order.order_items.new item: trial_subscription_plan, price: trial_subscription_plan.trial_price, subtotal: trial_subscription_plan.trial_price, order_item_type: 'prod', quantity: 1, title: trial_subscription_plan.title, tax_code: trial_subscription_plan.tax_code
		order
	}
	let(:new_trial_subscription_plan_order3) {
		order = SwellEcom::Order.new( billing_address: address3, shipping_address: address3, user: user )
		order.order_items.new item: trial_subscription_plan, price: trial_subscription_plan.trial_price, subtotal: trial_subscription_plan.trial_price, order_item_type: 'prod', quantity: 1, title: trial_subscription_plan.title, tax_code: trial_subscription_plan.tax_code
		order
	}
	let(:new_trial_subscription_plan_order4) {
		order = SwellEcom::Order.new( billing_address: address4, shipping_address: address4, user: user )
		order.order_items.new item: trial_subscription_plan, price: trial_subscription_plan.trial_price, subtotal: trial_subscription_plan.trial_price, order_item_type: 'prod', quantity: 1, title: trial_subscription_plan.title, tax_code: trial_subscription_plan.tax_code
		order
	}

	before :all do
		@api_key = ENV['TAX_JAR_API_KEY']
		@default_args = {
			api_key: @api_key
		}
	end

	it "should instantiate" do

		tax_jar_service = SwellEcom::TaxServices::TaxJarTaxService.new( @default_args )

		expect( tax_jar_service.is_a?( SwellEcom::TaxServices::TaxJarTaxService ) ).to eq true
	end

	it "should calculate taxes" do

		tax_jar_service = SwellEcom::TaxServices::TaxJarTaxService.new( @default_args )

		order = new_trial_subscription_plan_order
		order.save

		expect( tax_jar_service.calculate( order ).is_a?( SwellEcom::Order ) ).to eq true

		tax_order_items = order.order_items.select{|oi| oi.tax? }

		expect( tax_order_items.count ).to eq 1
		expect( tax_order_items.collect(&:subtotal).sum ).to eq 8

		# @todo add more coverage for different states.

	end

	it "should calculate taxes for tennessee" do

		tax_jar_service = SwellEcom::TaxServices::TaxJarTaxService.new( @default_args )

		order = new_trial_subscription_plan_order2
		order.save

		expect( tax_jar_service.calculate( order ).is_a?( SwellEcom::Order ) ).to eq true

		tax_order_items = order.order_items.select{|oi| oi.tax? }

		expect( tax_order_items.count ).to eq 0
		expect( tax_order_items.collect(&:subtotal).sum ).to eq 0

		# @todo add more coverage for different states.

	end

	it "should calculate taxes for london" do

		tax_jar_service = SwellEcom::TaxServices::TaxJarTaxService.new( @default_args )

		order = new_trial_subscription_plan_order4
		order.save

		expect( tax_jar_service.calculate( order ).is_a?( SwellEcom::Order ) ).to eq true

		tax_order_items = order.order_items.select{|oi| oi.tax? }

		expect( tax_order_items.count ).to eq 0
		expect( tax_order_items.collect(&:subtotal).sum ).to eq 0

		# @todo add more coverage for different states.

	end

	it "should calculate taxes for Washington, DC" do

		tax_jar_service = SwellEcom::TaxServices::TaxJarTaxService.new( @default_args )

		order = new_trial_subscription_plan_order3
		order.save

		expect( tax_jar_service.calculate( order ).is_a?( SwellEcom::Order ) ).to eq true

		tax_order_items = order.order_items.select{|oi| oi.tax? }

		expect( tax_order_items.count ).to eq 0
		expect( tax_order_items.collect(&:subtotal).sum ).to eq 0

		# @todo add more coverage for different states.

	end

	it "should process taxes" do

		tax_jar_service = SwellEcom::TaxServices::TaxJarTaxService.new( @default_args )

		order = new_trial_subscription_plan_order
		order.save

		expect( tax_jar_service.calculate( order ).is_a?( SwellEcom::Order ) ).to eq true

		tax_order_items = order.order_items.select{|oi| oi.tax? }

		expect( tax_order_items.count ).to eq 1
		expect( tax_order_items.collect(&:subtotal).sum ).to eq 8

		order.code = "TEST-#{SecureRandom.uuid}"
		order.created_at = Time.now
		order.save

		expect( tax_jar_service.process( order ).is_a?( Taxjar::Order ) ).to eq true

		expect( tax_jar_service.process( order ).is_a?( Taxjar::Order ) ).to eq true

	end

end
