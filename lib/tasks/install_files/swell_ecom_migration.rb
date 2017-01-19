class SwellEcomMigration < ActiveRecord::Migration
	def change

		enable_extension 'hstore'


		create_table :carts do |t|
			t.references	:user
			t.integer		:status, default: 1
			t.string		:ip
			t.timestamps
		end

		create_table :cart_items do |t|
			t.references 	:item, polymorphic: true
			t.integer 		:quantity, default: 1
			t.timestamps
		end
		add_index :cart_items, [ :item_id, :item_type ]

		create_table :coupons do |t| 
			t.references 	:valid_for_item, polymoprhic: true # valid for specific item
			t.string 		:valid_for_email # to give to specific user
			t.string 		:title 
			t.string 		:code
			t.text 			:description
			t.string 		:discount_type
			t.integer 		:discount, default: 0
			t.string 		:discount_base, default: 'item' # 'total' => price + tax + shipping, 'shipping' => discount 100% is free shipping, 'tax' => discount 100% is free tax
			t.integer 		:max_redemptions, default: 1
			t.string 		:duration_type, default: 'once' # for subscriptions: 'repeat', 'forever'
			t.string 		:duration_days, default: 0 # if duration_type is repeat, how many days to continue
			t.datetime 		:publish_at
			t.datetime 		:expires_at 
			t.integer 		:status, default: 1
			t.hstore		:properties, default: {}
			t.timestamps
		end
		# add_index :coupons, [ :valid_for_item_id, :valid_for_item_type ], name: 'idx_item'
		add_index :coupons, :valid_for_email
		add_index :coupons, :code

		create_table :coupon_redemptions do |t|
			t.references	:coupon 
			t.references 	:order
			t.references 	:user
			t.string 		:email 
			t.integer 		:applied_discount 
			t.integer 		:status, default: 1
			t.timestamps 
		end
		add_index :coupon_redemptions, :coupon_id
		add_index :coupon_redemptions, :order_id
		add_index :coupon_redemptions, :user_id
		add_index :coupon_redemptions, :email

		create_table :geo_addresses do |t|
			t.references	:user
			t.references	:geo_state
			t.references	:geo_country
			t.integer 		:status
			t.string		:address_type
			t.string		:title
			t.string		:first_name
			t.string		:last_name
			t.string		:street
			t.string		:street2
			t.string		:city
			t.string		:state
			t.string		:zip
			t.string		:phone
			t.boolean		:preferred, :default => false
			t.timestamps
		end
		add_index :geo_addresses, :user_id
		add_index :geo_addresses, [ :geo_country_id, :geo_state_id ]

		create_table :geo_countries do |t|
			t.string   :name
			t.string   :abbrev
			t.timestamps
		end

		create_table :geo_states do |t|
			t.references	:geo_country
			t.string		:name
			t.string		:abbrev
			t.string		:country
			t.timestamps
		end
		add_index :geo_states, :geo_country_id

		create_table :orders do |t|
			t.references 	:user
			t.references 	:cart
			t.references 	:billing_address
			t.references 	:shipping_address
			t.string 		:code
			t.string 		:email
			t.integer 		:status, default: 0
			t.integer 		:subtotal, defualt: 0
			t.integer 		:tax_amount, defualt: 0
			t.integer 		:shipping_amount, defualt: 0
			t.integer 		:discount, defualt: 0
			t.integer 		:total, defualt: 0
			t.string 		:currency, default: 'USD'
			t.text 			:customer_comment
			t.datetime 		:fulfilled_at
			t.timestamps
		end
		add_index 	:orders, [ :user_id, :billing_address_id, :shipping_address_id ], name: 'user_id_addr_indx'
		add_index 	:orders, [ :email, :billing_address_id, :shipping_address_id ], name: 'email_addr_indx'
		add_index 	:orders, [ :email, :status ]
		add_index 	:orders, :code, unique: true

		create_table :order_items do |t|
			t.references 	:order
			t.references 	:item, polymorphic: true
			t.integer 		:quantity, default: 1
			t.integer 		:subtotal, default: 0
			t.integer 		:tax_amount, defualt: 0
			t.integer 		:shipping_amount, defualt: 0
			t.integer 		:discount, defualt: 0
			t.integer 		:total, defualt: 0
			t.timestamps
		end
		add_index :order_items, [ :item_id, :item_type ]

		create_table :products do |t|
			t.references 	:category
			t.string 		:title
			t.string		:caption
			t.string 		:slug
			t.string 		:avatar
			t.string 		:fulfillment_type, default: 'self' # digital, printful
			t.integer		:status, 	default: 0
			t.text 			:description
			t.text 			:content
			t.datetime		:publish_at
			t.datetime		:preorder_at
			t.datetime		:release_at
			t.integer 		:suggested_price, default: 0
			t.integer 		:price, default: 0
			t.string 		:currency, default: 'USD'
			t.integer 		:inventory, default: -1
			t.string 		:tags, array: true, default: '{}'
			t.hstore		:properties, default: {}
			t.timestamps
		end
		add_index :products, :tags, using: 'gin'
		add_index :products, :category_id
		add_index :products, :slug, unique: true
		add_index :products, :status

		create_table :refunds do |t|
			t.references 	:order
			t.integer 		:item_amount, default: 0
			t.integer 		:shipping_amount, default: 0
			t.integer 		:tax_amount, default: 0
			t.integer 		:total_amount, default: 0
			t.string 		:currency, default: 'USD'
			t.text 			:comment
			t.integer 		:status, default: 0
			t.timestamps
		end

		create_table :skus do |t|
			t.references	:product
			t.string 		:code 
			t.integer 		:price, 	default: 0
			t.integer 		:inventory, default: -1
			t.string 		:currency, default: 'USD'
			t.hstore		:properties, default: {}
			t.timestamps
		end
		add_index :skus, :code, unique: true

		create_table :subscriptions do |t|
			t.string		:title
			t.string 		:slug
			t.string 		:caption
			t.text 			:description 
			t.string 		:interval, default: 'month' # day, week, month, year
			t.integer 		:interval_count, default: 1
			t.integer 		:trial_period_days, default: 0
			t.integer		:price, default: 0
			t.string 		:currency, default: 'USD'
			t.integer 		:status, default: 1
			t.hstore		:properties, default: {}
		end
		add_index :subscriptions, :slug, unique: true

		create_table :subscribings do |t| 
			t.references 	:user
			t.references 	:subscription 
			t.string 		:email 
			t.integer 		:status, default: 1
			t.hstore		:properties, default: {}
			t.timestamps 
		end
		add_index :subscribings, :user_id
		add_index :subscribings, :subscription_id
		add_index :subscribings, :email

		create_table :tax_rates do |t|
			t.references 	:geo_state
			t.float			:rate, default: 0
			t.timestamps
		end
		add_index :tax_rates, :geo_state_id

		create_table :transactions do |t|
			t.references 	:parent, polymorphic: true 	# order, refund
			t.string 		:transaction_type   # order_payment, subscription_payment, refund
			t.string	 	:provider
			t.string 		:reference
			t.integer 		:amount, default: 0
			t.integer		:status, default: 1
			t.timestamps
		end
		add_index :transactions, [ :parent_id, :parent_type ]
		add_index :transactions, [ :transaction_type ]
		add_index :transactions, [ :reference ]
		add_index :transactions, [ :status, :reference ]


		# todo:
		# - product variants
		# - coupons
		# - bundles
		# - inventory?
		# - deal with subscriptions?
		# - ?refunds/transactions?


	end
end
