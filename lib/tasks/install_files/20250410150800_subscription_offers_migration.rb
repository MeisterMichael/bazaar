class SubscriptionOffersMigration < ActiveRecord::Migration[7.1]
	def change

		# drop_table :bazaar_subscription_plans
		# drop_table :bazaar_subscription_prices
		drop_table :bazaar_subscription_logs

		create_table :bazaar_subscription_offers do |t|
			t.belongs_to :subscription
			t.belongs_to :offer
			# t.belongs_to :parent, default: nil # copied or merged from

			t.integer :status, default: 1 # trash, canceled, draft, active
			t.integer :quantity, default: 1

			# The next offer interval to process
			# t.integer :next_offer_interval, default: 1

			# The interval in which this subscription offer
			# will be next executed.
			t.integer :next_subscription_interval, default: nil

			t.json :properties, default: {}

			t.timestamp :canceled_at, default: nil # when canceled
			t.timestamps

			t.index [:status,:subscription_id,:next_subscription_interval]
			t.index [:status,:offer_id]
		end

		create_table :bazaar_subscription_logs do |t|
			t.belongs_to :subscription
			# t.belongs_to :subscription_period, default: nil
			t.belongs_to :subscription_offer, default: nil
			t.belongs_to :order, default: nil
			t.belongs_to :order_offer, default: nil

			t.integer :offer_interval, default: nil
			t.integer :subscription_interval, default: nil

			t.string :event_type # cancel, restore, failed, error, success
			t.string :subject
			t.string :reason
			t.text :details

			t.json :properties, default: {}

			t.timestamps
			t.index [:offer_interval,:subscription_id]
			t.index [:subscription_interval,:subscription_id]
		end

		change_table :bazaar_subscriptions do |t|
			t.integer :estimated_tax, default: nil
			t.integer :estimated_shipping, default: nil
			t.integer :estimated_discount, default: nil
			t.integer :estimated_subtotal, default: nil
			t.integer :estimated_total, default: nil
			t.integer :estimated_interval, default: nil
			t.timestamp :estimate_update_at, default: nil
		end

		change_table :bazaar_order_offers do |t|
			t.belongs_to :subscription_offer, default: nil
			t.integer :offer_interval, default: nil
		end

	end
end
