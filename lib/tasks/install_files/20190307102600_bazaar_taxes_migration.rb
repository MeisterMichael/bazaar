class BazaarTaxesMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :bazaar_shipments, :declared_value, :integer, default: nil

		add_column :bazaar_orders, :tax_breakdown, :json, default: {}

		add_column :bazaar_shipments, :tax, :integer, default: nil
		add_column :bazaar_shipments, :tax_breakdown, :json, default: {}

		add_column :bazaar_order_offers, :tax, :integer, default: nil
		add_column :bazaar_order_offers, :tax_breakdown, :json, default: {}

	end

end
