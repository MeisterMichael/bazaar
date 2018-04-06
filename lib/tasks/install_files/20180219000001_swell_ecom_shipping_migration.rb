class SwellEcomShippingMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :products, :package_shape, :integer, default: 0
		add_column :subscription_plans, :package_shape, :integer, default: 0
		add_column :product_variants, :package_shape, :integer, default: 0

		add_column :products, :package_weight, :float, default: nil
		add_column :subscription_plans, :package_weight, :float, default: nil
		add_column :product_variants, :package_weight, :float, default: nil

		add_column :products, :package_length, :float, default: nil
		add_column :subscription_plans, :package_length, :float, default: nil
		add_column :product_variants, :package_length, :float, default: nil

		add_column :products, :package_width, :float, default: nil
		add_column :subscription_plans, :package_width, :float, default: nil
		add_column :product_variants, :package_width, :float, default: nil

		add_column :products, :package_height, :float, default: nil
		add_column :subscription_plans, :package_height, :float, default: nil
		add_column :product_variants, :package_height, :float, default: nil

	end
end
