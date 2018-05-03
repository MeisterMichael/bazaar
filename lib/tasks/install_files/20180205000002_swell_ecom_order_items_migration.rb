class SwellEcomOrderItemsMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :order_items, :sku, :string, default: nil
		add_column :order_items, :parent_id, :integer, default: nil
		add_column :subscription_plans, :product_sku, :string, default: nil
		add_column :subscription_plans, :trial_sku, :string, default: nil

	end
end
