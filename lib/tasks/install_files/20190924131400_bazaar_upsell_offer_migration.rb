class BazaarUpsellOfferMigration < ActiveRecord::Migration[5.1]
	def change

		create_table :bazaar_upsell_offers do |t|
			t.references	:src_product
			t.references	:src_offer
			t.references	:offer
			t.timestamps
		end

		add_column :bazaar_offers, :cart_title, :string, default: nil

	end
end
