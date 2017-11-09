require "spec_helper"

describe "AuthorizeDotNetTransactionService" do

	let(:address) { SwellEcom::GeoAddress.new(  ) }
	let(:subscription_plan) { SwellEcom::SubscriptionPlan.new( title: 'Test Subscription Plan', trial_price: 99 ) }

	before :all do
	end

	it "should support instantiation" do
		SwellEcom::TransactionServices::AuthorizeDotNetTransactionService.new.should be_instance_of(SwellEcom::TransactionServices::AuthorizeDotNetTransactionService)
	end

	it "should support orders" do

		transaction_service	= SwellEcom::TransactionServices::AuthorizeDotNetTransactionService.new()

		order = SwellEcom::Order.new(
			billing_address: address,
			shipping_address: address,
		)
		order.order_items.new item: subscription_plan, price: subscription_plan.trial_price, subtotal: subscription_plan.trial_price, order_item_type: 'prod', quantity: 1, title: subscription_plan.title, tax_code: subscription_plan.tax_code

		transaction = transaction_service.process( order )

		transaction.should be_instance_of(SwellEcom::Transaction)
		order.errors.present?.should be_falsey

	end

end
