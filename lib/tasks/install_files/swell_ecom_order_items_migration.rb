class SwellEcomOrderItemsMigration < ActiveRecord::Migration
	def change

		add_column :order_items, :sku, :string, default: nil
		add_column :order_items, :parent_id, :integer, default: nil

	end
end
