require "spec_helper"

describe "AuthorizeDotNetTransactionService" do

	before :all do
	end

	it "should support instantiation" do
		SwellEcom::TransactionServices::AuthorizeDotNetTransactionService.new.should be_instance_of(SwellEcom::TransactionServices::AuthorizeDotNetTransactionService)
	end

end
