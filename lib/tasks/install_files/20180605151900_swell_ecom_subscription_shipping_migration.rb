class SwellEcomSubscriptionShippingMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :subscriptions, :shipping, :integer, default: nil
		add_column :subscriptions, :tax, :integer, default: nil

	end
end
