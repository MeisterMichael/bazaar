class BazaarShipmentPriceMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :bazaar_shipments, :price, :int, default: nil
		add_column :bazaar_shipments, :shipping_carrier_service_id, :bigint, default: nil

	end

end
