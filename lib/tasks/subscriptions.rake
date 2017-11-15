# desc "Explaining what the task does"
namespace :swell_ecom do

	task process_subscriptions: :environment do

		SwellEcom::SubscriptionService.new.charge_subscriptions

	end

end
