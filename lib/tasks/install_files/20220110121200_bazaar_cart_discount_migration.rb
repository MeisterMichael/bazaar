class BazaarCartDiscountMigration < ActiveRecord::Migration[5.1]
	def change
		change_table :bazaar_carts do |t|
			t.belongs_to 	:discount, default: nil
		end
	end
end
