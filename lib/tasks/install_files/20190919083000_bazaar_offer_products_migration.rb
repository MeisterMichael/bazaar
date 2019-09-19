class BazaarOfferProductsMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :bazaar_offers, :product_id, :bigint, default: nil
		add_index :bazaar_offers, [:product_id,:status,:created_at]

	end
end
