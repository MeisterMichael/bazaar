class SwellEcomWholesaleMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :users, :wholesale_profile_id, :integer, default: nil
		add_index  :users, [ :wholesale_profile_id, :status ]
		add_column :users, :preferred_shipping_address_id, :integer, default: nil
		add_column :users, :preferred_billing_address_id, :integer, default: nil

		add_column :geo_addresses, :tags, :string, default: [], array: true
    	add_index :geo_addresses, ["tags"], using: :gin


		create_table :wholesale_profiles do |t|
			t.string 		:title
			t.text 			:description
			t.integer		:status, 			default: 0
			t.boolean		:default_profile, 	default: false
			t.hstore		:properties, 		default: {}
			t.timestamps
		end
		add_index :wholesale_profiles, [ :title, :status ]
		add_index :wholesale_profiles, [ :status ]

		create_table :wholesale_items do |t|
			t.references 	:wholesale_profile
			t.references 	:item, polymorphic: true
			t.integer		:min_quantity,		default: 0
			t.integer		:price,				default: 0
		end
		add_index :wholesale_items, [ :wholesale_profile_id, :item_id, :item_type, :min_quantity ], name: 'index_wholesale_items_on_prof_id_and_item_and_min'
		add_index :wholesale_items, [ :wholesale_profile_id, :item_id, :item_type, :price ], name: 'index_wholesale_items_on_prof_id_and_item_and_price'
		add_index :wholesale_items, [ :wholesale_profile_id, :min_quantity ]
		add_index :wholesale_items, [ :wholesale_profile_id, :price ]

	end
end
