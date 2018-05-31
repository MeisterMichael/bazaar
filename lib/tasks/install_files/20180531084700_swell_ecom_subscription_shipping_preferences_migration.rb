class SwellEcomSubscriptionShippingPreferencesMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :subscriptions, :shipping_carrier_service_id, :integer

	end
end
