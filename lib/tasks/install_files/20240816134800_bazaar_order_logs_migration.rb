class BazaarOrderLogsMigration < ActiveRecord::Migration[7.1]
	def change

		create_table :bazaar_order_logs do |t|
			t.belongs_to "order"
			t.belongs_to "item", polymorphic: true, default: nil
			t.string "source"
			t.string "subject"
			t.text "details"
			t.json "properties", default: {}
			t.timestamps
		end
	end
end
