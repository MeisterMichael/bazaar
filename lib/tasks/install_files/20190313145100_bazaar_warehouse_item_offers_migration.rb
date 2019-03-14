class BazaarWarehouseItemOffersMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :bazaar_wholesale_items, :offer_id, :bigint, default: nil
		add_column :bazaar_wholesale_items, :sku_id, :bigint, default: nil

		add_index :bazaar_wholesale_items, :offer_id
		add_index :bazaar_wholesale_items, :sku_id

	end

end
