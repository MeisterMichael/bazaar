class BazaarCartOffersMigration < ActiveRecord::Migration[5.1]
	def change

		rename_table :bazaar_cart_items, :bazaar_cart_offers
		add_column :bazaar_cart_offers, :offer_id, :bigint, default: nil

	end
end
