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
			t.string 		:product_type, default: 'physical' # digital, subscription
			t.integer		:status, 	default: 0
			t.text 			:description
			t.text 			:content
			t.datetime		:publish_at
			t.datetime		:preorder_at
			t.datetime		:release_at
			t.integer 		:suggested_price
			t.integer 		:price
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

		create_table :tax_rates do |t|
			t.references 	:geo_state
			t.float			:rate
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
