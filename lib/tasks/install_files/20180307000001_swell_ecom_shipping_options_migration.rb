class SwellEcomShippingOptionsMigration < ActiveRecord::Migration[5.1]
	def change

		create_table :shipping_options do |t|
			t.string 		:name
			t.string 		:short_description
			t.string 		:description
			t.integer		:status, 	default: 0
			t.timestamps
		end

		create_table :shipping_carrier_services do |t|
			t.references 	:shipping_option
			t.string 		:name			# the app's customized name for this service
			t.string 		:description	# the app's customized description for this service
			t.string 		:carrier
			t.string 		:service_code
			t.string 		:service_name
			t.string 		:service_group
			t.string 		:service_description
			t.string		:delivery_category
			t.integer		:status, 	default: 0
			t.timestamps
		end
	end
end
