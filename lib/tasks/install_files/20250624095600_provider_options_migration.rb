class ProviderOptionsMigration < ActiveRecord::Migration[7.1]
	def change

		change_table :bazaar_orders do |t|
			t.json	:provider_customer_payment_profile_options, default: {}
		end

		change_table :bazaar_subscriptions do |t|
			t.json	:provider_customer_payment_profile_options, default: {}
		end

		change_table :bazaar_transactions do |t|
			t.json	:customer_payment_profile_options, default: {}
		end

	end
end
