class SwellEcomCartEmailMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :carts, :email, :string
		add_column :products, :cart_description, :text, default: nil
		add_column :subscription_plans, :cart_description, :text, default: nil

		add_column :geo_countries, :bill_to, :bool, default: true
		add_column :geo_countries, :ship_to, :bool, default: true

	end
end
