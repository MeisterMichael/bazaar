class CollectionSlugMigration < ActiveRecord::Migration[7.1]
	def change
		change_table :bazaar_collections do |t|
			t.string :slug
			t.index :slug, unique: true
		end
	end
end
