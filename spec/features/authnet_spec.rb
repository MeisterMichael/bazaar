require "spec_helper"

describe "AuthorizeDotNetTransactionService" do

	let(:user) { ::User.create( email: "#{(0...20).map { (65 + rand(26)).chr }.join}@groundswellent.com", first_name: 'Michael', last_name: (0...8).map { (65 + rand(26)).chr }.join ) }
	let(:address) { SwellEcom::GeoAddress.new( first_name: 'Michael', last_name: (0...8).map { (65 + rand(26)).chr }.join, zip: '92126', phone: "1#{(0...10).map { (rand(8)+1).to_s }.join}", city: 'San Diego', geo_country: SwellEcom::GeoCountry.new( name: 'United States', abbrev: 'US' ), geo_state: SwellEcom::GeoState.new( name: 'California', abbrev: 'CA' ) ) }
	let(:trial_subscription_plan) { SwellEcom::SubscriptionPlan.new( title: 'Test Trial Subscription Plan', trial_price: 99, price: 12900 ) }
	let(:subscription_plan) { SwellEcom::SubscriptionPlan.new( title: 'Test Subscription Plan', price: 12900 ) }
	let(:credit_card) { { card_number: '4111111111111111', expiration: '12/'+(Time.now + 1.year).strftime('%y'), card_code: '1234' } }
	let(:new_subscription_plan_order) {
		order = SwellEcom::Order.new( billing_address: address, shipping_address: address, user: user )
		order.order_items.new item: subscription_plan, price: subscription_plan.price, subtotal: subscription_plan.price, order_item_type: 'prod', quantity: 1, title: subscription_plan.title, tax_code: subscription_plan.tax_code
		order
	}
	let(:new_trial_subscription_plan_order) {
		order = SwellEcom::Order.new( billing_address: address, shipping_address: address, user: user )
		order.order_items.new item: subscription_plan, price: subscription_plan.trial_price, subtotal: subscription_plan.trial_price, order_item_type: 'prod', quantity: 1, title: subscription_plan.title, tax_code: subscription_plan.tax_code
		order
	}

	before :all do
		@api_login	= ENV['AUTHORIZE_DOT_NET_API_LOGIN_ID']
		@api_key	= ENV['AUTHORIZE_DOT_NET_TRANSACTION_API_KEY']
		@gateway	= :sandbox
	end

	it "should support instantiation" do
		SwellEcom::TransactionServices::AuthorizeDotNetTransactionService.new.should be_instance_of(SwellEcom::TransactionServices::AuthorizeDotNetTransactionService)
	end

	it "should support processing orders" do

		transaction_service	= SwellEcom::TransactionServices::AuthorizeDotNetTransactionService.new( API_LOGIN_ID: @api_login, TRANSACTION_API_KEY: @api_key, GATEWAY: @gateway )
		order = new_subscription_plan_order

		transaction = transaction_service.process( order, credit_card: credit_card )

		transaction.should be_instance_of(SwellEcom::Transaction)
		expect(order.errors.present?).to eq false
		expect(transaction.errors.present?).to eq false
		expect(transaction.approved?).to eq true
		expect(transaction.charge?).to eq true
		expect(transaction.amount).to eq 12900
		expect(transaction.signed_amount).to eq 12900

	end

	it "should support refunding transactions" do

		transaction_service	= SwellEcom::TransactionServices::AuthorizeDotNetTransactionService.new( API_LOGIN_ID: @api_login, TRANSACTION_API_KEY: @api_key, GATEWAY: @gateway )
		order = new_subscription_plan_order

		transaction = transaction_service.process( order, credit_card: credit_card )

		transaction.should be_instance_of(SwellEcom::Transaction)
		expect(order.errors.present?).to eq false
		expect(transaction.errors.present?).to eq false
		expect(transaction.approved?).to eq true
		expect(transaction.charge?).to eq true

		refund_transaction = transaction_service.refund( charge_transaction: transaction )

		refund_transaction.should be_instance_of(SwellEcom::Transaction)
		expect(refund_transaction.errors.present?).to eq false
		expect(refund_transaction.amount).to eq 12900
		expect(refund_transaction.signed_amount).to eq -12900
		expect(refund_transaction.void?).to eq true
		expect(refund_transaction.negative?).to eq true
		expect(refund_transaction.approved?).to eq true


	end

	# can't test because requires that transaction must have settled frist.
	# if transaction hasn't settled, then voiding the entire order is the only
	# option.
	# it "should support partial refunding transactions" do
	#
	# 	transaction_service	= SwellEcom::TransactionServices::AuthorizeDotNetTransactionService.new( API_LOGIN_ID: @api_login, TRANSACTION_API_KEY: @api_key, GATEWAY: @gateway )
	# 	order = new_subscription_plan_order
	#
	# 	transaction = transaction_service.process( order, credit_card: credit_card )
	#
	# 	transaction.should be_instance_of(SwellEcom::Transaction)
	# 	expect(order.errors.present?).to eq false
	# 	expect(transaction.errors.present?).to eq false
	# 	expect(transaction.approved?).to eq true
	# 	expect(transaction.charge?).to eq true
	#
	# 	refund_transaction = transaction_service.refund( charge_transaction: transaction, amount: 100 )
	#
	# 	refund_transaction.should be_instance_of(SwellEcom::Transaction)
	# 	expect(refund_transaction.errors.present?).to eq false
	# 	expect(refund_transaction.amount).to eq 100
	# 	expect(refund_transaction.signed_amount).to eq -100
	# 	expect(refund_transaction.refund?).to eq true
	# 	expect(refund_transaction.negative?).to eq true
	# 	expect(refund_transaction.approved?).to eq true
	#
	#
	# end

end
