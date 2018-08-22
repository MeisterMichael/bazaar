class SwellEcomGeoAddressHashCodeMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :geo_addresses, :hash_code, :text, default: nil
		add_index :geo_addresses, [:hash_code,:first_name,:last_name]
		add_index :geo_addresses, [:hash_code,:user_id]
		add_index :geo_addresses, [:hash_code,:id]

	end
end
