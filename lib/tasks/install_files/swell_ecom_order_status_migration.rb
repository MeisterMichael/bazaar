class SwellEcomOrderStatusMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :orders, :payment_status, :integer, default: 0
		add_column :orders, :fulfillment_status, :integer, default: 0

	end
end
