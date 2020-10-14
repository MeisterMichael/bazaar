# desc "Explaining what the task does"
namespace :bazaar_core do

	task payment_profile_expiration_reminder: :environment do

		subscriptions = Bazaar::Subscription.active
		subscriptions = subscriptions.where( payment_profile_expires_at: Time.now..1.month.from_now ).where.not( payment_profile_expires_at: nil )

		subscriptions.find_each do |subscription|

			if subscription.properties['payment_profile_expiration_reminder'].nil?

				subscription.properties = subscription.properties.merge( 'payment_profile_expiration_reminder' => Time.now.to_i )
				subscription.save

				BazaarCore::SubscriptionMailer.payment_profile_expiration_reminder( subscription ).deliver_now

			end

		end

	end

	task process_subscriptions: :environment do

		time_now = Time.now
		subscription_service = BazaarCore.subscription_service_class.constantize.new( BazaarCore.subscription_service_config )

		Bazaar::Subscription.ready_for_next_charge( time_now ).find_each do |subscription|

			begin

				order = subscription_service.charge_subscription( subscription, now: time_now )

				if subscription.failed?
					BazaarCore::SubscriptionMailer.renewal_failure( subscription ).deliver_now
				elsif order.errors.blank?
					BazaarCore::OrderMailer.receipt( order ).deliver_now
				end

			rescue Exception => e

				puts "Exception: #{e.message}"
				NewRelic::Agent.notice_error(e) if defined?( NewRelic )

			end

		end

	end

end
