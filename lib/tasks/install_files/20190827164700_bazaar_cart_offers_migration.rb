class BazaarCartOffersMigration < ActiveRecord::Migration[5.1]
	def change

		rename_table :bazaar_cart_items, :bazaar_cart_offers
		add_column :bazaar_cart_offers, :offer_id, :bigint, default: nil

		add_column :bazaar_offers, :product_id, :bigint, default: nil
		add_index :bazaar_offers, [:product_id,:status,:created_at]


	end
end
