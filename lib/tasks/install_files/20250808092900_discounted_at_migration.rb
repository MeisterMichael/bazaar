class DiscountedAtMigration < ActiveRecord::Migration[7.1]
	def change

		change_table :bazaar_carts do |t|
			t.timestamp	:discounted_at
			t.timestamp	:discount_expired_at
			t.index [:discounted_at,:discount_id]
			t.index [:discount_expired_at,:discount_id]
		end

	end
end
