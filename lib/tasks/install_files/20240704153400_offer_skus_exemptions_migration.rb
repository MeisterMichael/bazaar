class OfferSkusExemptionsMigration < ActiveRecord::Migration[7.1]
	def change
		change_table :bazaar_offer_skus do |t|
			t.integer :shipping_exemptions, default: 0
		end
		change_table :bazaar_shipment_skus do |t|
			t.integer :shipping_exemptions, default: 0
		end
	end
end
