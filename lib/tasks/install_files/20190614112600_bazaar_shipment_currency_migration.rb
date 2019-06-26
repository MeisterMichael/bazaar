class BazaarShipmentCurrencyMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :bazaar_shipments, :currency, :string, default: 'USD'

	end
end
