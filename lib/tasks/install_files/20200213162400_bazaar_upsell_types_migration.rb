class BazaarUpsellTypesMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :bazaar_upsell_offers, :upsell_type, :int, default: 1
		add_index	:bazaar_upsell_offers, [:upsell_type,:src_product_id]
		add_index	:bazaar_upsell_offers, [:upsell_type,:src_offer_id]

	end
end
