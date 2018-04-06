class SwellEcomSubscriptionCustomizationMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :subscriptions, :billing_interval_value, :integer, default: 1
		add_column :subscriptions, :billing_interval_unit, :string, default: "months"
		add_column :subscriptions, :trial_price, :integer
		add_column :subscriptions, :price, :integer

		add_column :subscription_plans, :item_id, :integer, default: nil
		add_column :subscription_plans, :item_type, :string, default: nil

		add_column :orders, :delivered_at, :datetime, default: nil
		add_column :orders, :discount, :integer, default: 0

	end
end
