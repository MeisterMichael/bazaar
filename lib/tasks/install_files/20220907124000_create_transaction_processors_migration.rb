class CreateTransactionProcessorsMigration < ActiveRecord::Migration[5.2]
	def change

		create_table	:bazaar_transaction_providers do |t|
			t.string			:name
			t.belongs_to	:merchant_identification, default: nil, index: {:name => "index_bazaar_transaction_providers_on_merchant_id"}
			t.text				:tags, default: [], array: true
			t.belongs_to	:transaction_provider_interface, index: {:name => "index_bazaar_transaction_providers_on_traprointerface"}
			t.json				:service_options, default: {} #encrypt it? or keep in ENV variables
			t.timestamps
		end

		create_table	:bazaar_transaction_provider_interfaces do |t|
			t.string			:name # PayPal, AmazonPay, AuthorizeDotNet
			t.string			:service_class_name
			t.timestamps
		end

		create_table	:bazaar_merchant_identifications do |t|
			t.string			:name
			t.string			:identifier
			t.timestamps
		end

		create_table	:transaction_provider_weights do |t|
			t.belongs_to	:transaction_provider
			t.integer			:percent_used, default: 0.01
			t.integer			:percent_used_sum
			t.string			:use_type
			t.integer			:status
			t.datetime		:archived_at, default: nil
			t.timestamps
		end

		change_table	:bazaar_transactions do |t|
			t.belongs_to	:transaction_provider
			t.belongs_to	:merchant_identification
		end

		change_table	:bazaar_orders do |t|
			t.belongs_to	:transaction_provider
			t.belongs_to	:merchant_identification
		end

		change_table	:bazaar_subscriptions do |t|
			t.belongs_to	:transaction_provider
			t.belongs_to	:merchant_identification
		end
	end
end
