class BazaarDiscountSubscriptionIntervalsMigration < ActiveRecord::Migration[5.1]
	def change
		change_table :bazaar_discounts do |t|
			t.integer	:min_subscription_interval , default: 1
			t.integer	:max_subscription_interval , default: nil
		end
	end
end
