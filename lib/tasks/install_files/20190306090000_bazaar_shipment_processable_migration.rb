class BazaarShipmentProcessableMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :bazaar_shipments, :processable_at, :datetime, default: nil

	end

end
