class SwellEcomCollectionMigration < ActiveRecord::Migration[5.1]
	def change

		create_table :collections do |t|
			t.string 		:title
			t.text 			:description
			t.text 			:avatar
			t.integer		:status, 			default: 0
			t.integer		:collection_type, 	default: 1
			t.integer		:availability,		default: 1 # anyone, private
			t.hstore		:properties, 		default: {}
			t.json			:query,				default: {}
			t.timestamps
		end
		add_index :collections, [ :title, :status, :availability ]
		add_index :collections, [ :status, :availability ]

		create_table :collection_items do |t|
			t.references 	:collection
			t.references 	:item, polymorphic: true
		end

	end
end
