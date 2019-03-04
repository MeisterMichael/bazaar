class BazaarShipmentPriceMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :bazaar_shipments, :price, :int, default: nil

	end

end
