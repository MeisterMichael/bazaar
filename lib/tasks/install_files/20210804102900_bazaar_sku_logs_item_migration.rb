class BazaarSkuLogsItemMigration < ActiveRecord::Migration[5.1]
	def change
		change_table :bazaar_skus do |t|
			t.json		:options,	default: {}
		end

		change_table :bazaar_shipment_logs do |t|
			t.references 	:item, polymorphic: true, default: nil
		end
	end
end
