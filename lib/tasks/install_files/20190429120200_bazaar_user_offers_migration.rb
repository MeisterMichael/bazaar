class BazaarUserOffersMigration < ActiveRecord::Migration[5.1]
	def change

		create_table :bazaar_user_offers do |t|
			t.references	:user
			t.references	:offer
			t.timestamps
		end

	end

end
