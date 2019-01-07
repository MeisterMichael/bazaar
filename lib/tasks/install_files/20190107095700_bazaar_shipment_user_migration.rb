class BazaarShipmentUserMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :bazaar_shipments, :user_id, :bigint, default: nil
		add_column :bazaar_shipment_skus, :shipping_code, :string, default: nil

	end
end
