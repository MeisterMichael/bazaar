class SwellEcomPreOrderMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :products, :availability, :integer, default: 1
		add_column :subscription_plans, :availability, :integer, default: 1
		add_column :product_variants, :availability, :integer, default: 1

		add_column :orders, :provider, :string, default: nil
		add_column :orders, :provider_customer_profile_reference, :string, default: nil
		add_column :orders, :provider_customer_payment_profile_reference, :string, default: nil

	end
end
