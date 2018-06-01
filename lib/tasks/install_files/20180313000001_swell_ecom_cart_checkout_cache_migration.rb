class SwellEcomCartCheckoutCacheMigration < ActiveRecord::Migration[5.1]
	def change
		add_column :carts, :first_name, :string
		add_column :carts, :last_name, :string
		add_column :carts, :checkout_cache, :json, default: {}
	end
end
