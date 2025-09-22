class RenewalAttemptMigration < ActiveRecord::Migration[7.1]
	def change

		change_table :bazaar_order_offers do |t|
			t.integer	:attempt, default: nil
			t.index [:attempt,:subscription_id,:order_id]
			t.index [:attempt,:subscription_offer_id,:order_id]
		end

		change_table :bazaar_orders do |t|
			t.integer	:attempt, default: nil
			t.index [:attempt,:parent_id,:status]
			t.index [:attempt,:status]
		end

	end
end
