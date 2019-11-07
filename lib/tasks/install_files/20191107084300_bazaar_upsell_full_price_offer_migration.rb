class BazaarUpsellFullPriceOfferMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :bazaar_upsell_offers, :full_price_offer_id, :bigint, default: nil

	end
end
