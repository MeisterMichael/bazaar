class CollectionItemSeqMigration < ActiveRecord::Migration[7.1]
	def change
		change_table :bazaar_collection_items do |t|
			t.integer :seq, default: nil
		end
	end
end
