class BazaarCurrencyMigration < ActiveRecord::Migration[5.1]
	def change


		create_table :bazaar_currencies do |t|
			t.string	:name
			t.string	:code
			t.float		:usd_conversion_rate
			t.json		:history, default: {}
			t.timestamps
		end

	end
end
