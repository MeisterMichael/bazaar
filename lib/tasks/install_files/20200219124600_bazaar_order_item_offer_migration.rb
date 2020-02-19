class BazaarOrderItemOfferMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :bazaar_order_items, :offer_id, :bigint, default: nil
		add_index :bazaar_order_items, :offer_id

	end
end
