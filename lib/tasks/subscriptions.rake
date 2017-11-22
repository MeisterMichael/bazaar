# desc "Explaining what the task does"
namespace :swell_ecom do

	task process_subscriptions: :environment do

		time_now = Time.now
		subscription_service = SwellEcom::SubscriptionService.new

		SwellEcom::Subscription.ready_for_next_charge( time_now ).find_each do |subscription|

			begin

				order = subscription_service.charge_subscription( subscription, now: time_now )

				SwellEcom::OrderMailer.receipt( order ).deliver_now unless order.errors.present?

			rescue Exception => e

				puts "Exception: #{e.message}"
				NewRelic::Agent.notice_error(e) if defined?( NewRelic )

			end

		end

	end

end
