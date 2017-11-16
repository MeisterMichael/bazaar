# desc "Explaining what the task does"
namespace :swell_ecom do

	task process_subscriptions: :environment do

		subscription_service = SwellEcom::SubscriptionService.new

		SwellEcom::Subscription.ready_for_next_charge.find_each do |subscription|

			begin

				order = subscription_service.charge_subscription( subscription, now: now )

				OrderMailer.receipt( order ).deliver_now unless order.errors.present?


			rescue Exception => e

				# @todo log error, and carry on

			end

		end

	end

end
