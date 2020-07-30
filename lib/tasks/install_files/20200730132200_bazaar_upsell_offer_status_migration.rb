class BazaarUpsellOfferStatusMigration < ActiveRecord::Migration[5.1]
	def change
		change_table :bazaar_upsell_offers do |t|
			t.integer	:status, default: 1
			t.index [:status, :src_offer_id]
			t.index [:status, :offer_id]
		end

		change_column :bazaar_upsell_offers, :status, :integer, default: 0
	end
end
