class BazaarOfferTagsMigration < ActiveRecord::Migration[5.1]
	def change
		change_table :bazaar_offers do |t|
			t.string	:tags, default: [], array: true
		end
	end
end
