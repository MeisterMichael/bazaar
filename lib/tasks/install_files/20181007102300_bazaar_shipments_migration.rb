class BazaarShipmentsMigration < ActiveRecord::Migration[5.1]
	def change

		# the pricing template for a subscription
		create_table :bazaar_offer_prices do |t|
			t.belongs_to	:parent_obj, polymorphic: true, index: { name: 'index_bazaar_offer_prices_on_parent_obj' }
			t.integer			:start_interval, default: 1
			t.integer			:max_intervals, default: nil
			t.integer			:price, default: 0
			t.integer			:status, default: 1
			t.datetime		:trashed_at, default: nil
			t.json				:properties, default: {}
			t.timestamps
		end

		# the schedule template for a subscription
		create_table :bazaar_offer_schedules do |t|
			t.belongs_to	:parent_obj, polymorphic: true, index: { name: 'index_bazaar_offer_schedules_on_parent_obj' }
			t.integer			:start_interval, default: 1
			t.integer			:max_intervals, default: nil
			t.string			:interval_unit, default: "month"
			t.integer			:interval_value, default: 1
			t.integer			:status, default: 1
			t.datetime		:trashed_at, default: nil
			t.json				:properties, default: {}
			t.timestamps
		end

		create_table :bazaar_offer_skus do |t|
			t.belongs_to	:parent_obj, polymorphic: true
			t.belongs_to	:sku
			t.integer			:quantity, default: 1
			t.integer			:start_interval, default: 1
			t.integer			:max_intervals, default: nil
			t.integer			:status, default: 1
			t.integer			:apply, default: 1
			t.datetime		:trashed_at, default: nil
			t.json				:properties, default: {}
			t.timestamps
		end

		# the pricing for a subscription
		create_table :bazaar_subscription_prices do |t|
			t.belongs_to	:subscription
			t.integer			:start_interval, default: 1
			t.integer			:max_intervals, default: nil
			t.integer			:price, default: 0
			t.integer			:status, default: 1
			t.datetime		:trashed_at, default: nil
			t.json				:properties, default: {}
			t.timestamps
		end

		# the schedule for a subscription
		create_table :bazaar_subscription_schedules do |t|
			t.belongs_to	:subscription
			t.integer			:start_interval, default: 1
			t.integer			:max_intervals, default: 1
			t.string			:interval_unit, default: "month"
			t.integer			:interval_value, default: 1
			t.integer			:status, default: 1
			t.datetime		:trashed_at, default: nil
			t.json				:properties, default: {}
			t.timestamps
		end

		create_table :bazaar_shipments do |t|
			t.string			:code
			t.integer			:status, default: 0
			t.string			:carrier_status, default: nil
			t.text				:notes, default: nil
			t.belongs_to	:order, default: nil
			t.string			:email, default: nil

			# The Who - is preparing and delivering the shipment
			t.string			:fulfilled_by, default: nil
			t.string			:fulfillment_id, default: nil

			# The What - size and weight of the shipment
			t.float				:length
			t.float				:width
			t.float				:height
			t.integer			:shape, default: 0
			t.float				:weight
			t.integer			:cost

			# The Where - it's going, coming from and where it is along the way
			t.belongs_to	:destination_address
			t.belongs_to	:source_address
			t.belongs_to	:warehouse
			t.string			:tracking_code, default: nil
			t.string			:tracking_url, default: nil

			# The When
			t.datetime		:estimated_delivered_at
			t.datetime		:canceled_at
			t.datetime		:packed_at
			t.datetime		:shipped_at
			t.datetime		:delivered_at
			t.datetime		:returned_at

			# The How - the shipment is being sent
			t.string			:carrier, default: nil
			t.string			:carrier_service_level, default: nil
			t.string			:requested_service_level, default: 'standard'

			t.hstore			:properties, default: {}
			t.timestamps
		end

		create_table :bazaar_shipment_logs do |t|
			t.belongs_to	:shipment
			t.string			:carrier_status, default: nil
			t.string			:subject
			t.text				:details
			t.json				:properties, default: {}
			t.timestamps
		end

		create_table :bazaar_shipment_skus do |t|
			t.belongs_to	:shipment
			t.belongs_to	:sku
			t.integer			:quantity, default: 1
			t.timestamps
		end

		create_table :bazaar_skus do |t|
			t.string			:name
			t.text				:description
			t.string			:code
			t.integer			:status, default: 0
			t.float				:length, default: nil
			t.float				:width, default: nil
			t.float				:height, default: nil
			t.integer			:shape, default: 0
			t.float				:weight, default: nil
			t.integer			:sku_cost, default: nil
			t.integer			:sku_value, default: nil
			t.integer			:restriction_type, default: 0
			t.timestamps
		end

		create_table :bazaar_sku_countries do |t|
			t.belongs_to	:sku
			t.belongs_to	:geo_country
			t.timestamps
		end

		create_table :bazaar_warehouses do |t|
			t.string			:name
			t.string			:slug
			t.belongs_to	:geo_address
			t.integer			:status, default: 0
			t.integer			:restriction_type, default: 0
			t.timestamps
		end

		create_table :bazaar_warehouse_countries do |t|
			t.belongs_to	:warehouse
			t.belongs_to	:geo_country
			t.timestamps
		end

		create_table :bazaar_warehouse_skus do |t|
			t.belongs_to	:warehouse
			t.belongs_to	:sku
			t.string			:warehouse_code, default: nil
			t.integer			:quantity, default: 0
			t.datetime		:quantity_updated_at
			t.integer			:status, default: 0
			t.integer			:priority, default: 1
			t.integer			:restriction_type, default: 0
			t.json				:properties, default: {}
			t.timestamps
		end

		create_table :bazaar_warehouse_sku_countries do |t|
			t.belongs_to	:sku
			t.belongs_to	:geo_country
			t.timestamps
		end

	end
end
