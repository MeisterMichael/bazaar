class BazaarWarehouseStateMigration < ActiveRecord::Migration[5.1]
	def change

		rename_column :bazaar_skus, :restriction_type, :country_restriction_type
		add_column :bazaar_skus, :state_restriction_type, :integer, default: 0

		rename_column :bazaar_warehouses, :restriction_type, :country_restriction_type
		add_column :bazaar_warehouses, :state_restriction_type, :integer, default: 0

		rename_column :bazaar_warehouse_skus, :restriction_type, :country_restriction_type
		add_column :bazaar_warehouse_skus, :state_restriction_type, :integer, default: 0

		create_table :bazaar_warehouse_states do |t|
			t.belongs_to	:warehouse
			t.belongs_to	:geo_state
			t.timestamps
		end

	end
end
