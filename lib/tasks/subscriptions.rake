# desc "Explaining what the task does"
namespace :swell_ecom do

	task :process_subscriptions do

		SwellEcom::Subscription.active.where( 'next_charged_at < :now', now: Time.now ).find_each do |subscription|

			# @todo create order, process transaction
			# @todo mark subscription as failed if the transaction failed
			# @todo send receipt via email

		end

	end

	task :send_subscription_reminders do

		reminder_day = Time.now + 1.week

		# @todo remind subscribers of upcoming renewals

	end

end
