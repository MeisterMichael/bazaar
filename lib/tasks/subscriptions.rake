# desc "Explaining what the task does"
namespace :swell_ecom do

	task payment_profile_expiration_reminder: :environment do

		subscriptions = SwellEcom::Subscription.active
		subscriptions = subscriptions.where( 'payment_profile_expires_at > ?', 1.month.ago )

		subscriptions.find_each do |subscription|

			unless subscription.properties['payment_profile_expiration_reminder']

				subscription.properties = subscription.properties.merge( 'payment_profile_expiration_reminder' => 'sent' )
				subscription.save
				
				SwellEcom::SubscriptionMailer.payment_profile_expiration_reminder( subscription ).deliver_now
			end

		end

	end

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
