class OrderOfferUpsellMigration < ActiveRecord::Migration[7.1]
	def change
		change_table :bazaar_order_offers do |t|
			t.belongs_to 	:upsell_offer, default: nil
			t.belongs_to 	:upsell, default: nil
			t.belongs_to 	:bazaar_media_relation, default: nil
		end

		change_table :bazaar_cart_offers do |t|
			t.belongs_to 	:upsell_offer, default: nil
			t.belongs_to 	:upsell, default: nil
			t.belongs_to 	:bazaar_media_relation, default: nil
		end
	end
end
