class SwellEcomMigration < ActiveRecord::Migration[5.1]
	def change

		create_table :carts do |t|
			t.references	:user
			t.references	:order
			t.integer		:status, default: 1
			t.integer		:subtotal, default: 0
			t.integer 		:estimated_tax, default: 0
			t.integer 		:estimated_shipping, default: 0
			t.integer 		:estimated_total, default: 0
			t.string		:ip
			t.hstore		:properties, 	default: {}
			t.timestamps
		end

		create_table :cart_items do |t|
			t.references 	:cart
			t.references 	:item, polymorphic: true
			t.integer 		:quantity, default: 1
			t.integer 		:price, default: 0
			t.integer 		:subtotal, default: 0
			t.hstore		:properties, 	default: {}
			t.timestamps
		end

		create_table :orders do |t|
			t.references 	:user
			t.references 	:billing_address
			t.references 	:shipping_address
			t.string 		:code
			t.string 		:email
			t.string		:ip
			t.integer 		:status, default: 0
			t.integer 		:subtotal, default: 0
			t.integer 		:tax, default: 0
			t.integer 		:shipping, default: 0
			t.integer 		:total, defualt: 0
			t.string 		:currency, default: 'USD'
			t.text 			:customer_notes
			t.text 			:support_notes
			t.datetime 		:fulfilled_at
			t.hstore		:properties, 	default: {}
			t.timestamps
		end
		add_index 	:orders, [ :user_id, :billing_address_id, :shipping_address_id ], name: 'user_id_addr_indx'
		add_index 	:orders, [ :email, :billing_address_id, :shipping_address_id ], name: 'email_addr_indx'
		add_index 	:orders, [ :email, :status ]
		add_index 	:orders, :code, unique: true

		create_table :order_items do |t|
			t.references 	:order
			t.references 	:item, polymorphic: true
			t.string 		:title
			t.integer 		:quantity, default: 1
			t.integer 		:price, default: 0
			t.integer 		:subtotal, default: 0
			t.string		:tax_code, default: nil
			t.integer		:order_item_type, default: 1
			t.hstore		:properties, 	default: {}
			t.timestamps
		end
		add_index :order_items, [ :item_id, :item_type, :order_id ]
		add_index :order_items, [ :order_item_type, :order_id ]


		create_table :products do |t|
			t.references  :category
			t.text     :shopify_code
			t.string   :title
			t.string   :caption
			t.integer  :seq,             default: 1
			t.string   :slug
			t.string   :avatar
			t.string   :brand_model
			t.integer  :status,          default: 0
			t.text     :description
			t.text     :content
			t.datetime :publish_at
			t.integer  :price,           default: 0
			t.integer  :suggested_price, default: 0
			t.integer  :shipping_price,  default: 0
			t.string   :currency,        default: "USD"
			t.string   :tags,            default: [],      array: true
			t.hstore   :properties,      default: {}
			t.datetime :created_at
			t.datetime :updated_at
			t.string   :brand
			t.string   :model
			t.text     :size_info
			t.text     :notes
			t.integer  :collection_id
			t.string   :tax_code,        default: "00000"
		end
		add_index :products, :tags, using: 'gin'
		add_index :products, :slug, unique: true
		add_index :products, :status
		add_index :products, :seq

		create_table :product_variants do |t|
			t.references 	:product
			t.string 		:title
			t.string 		:slug
			t.string 		:avatar
			t.string 		:option_name, default: :size
			t.string 		:option_value
			t.text 			:description
			t.integer 		:status, default: 1
			t.integer 		:seq, default: 1
			t.integer 		:price, default: 0
			t.integer 		:shipping_price, default: 0
			t.integer 		:inventory, default: -1
			t.hstore 		:properties, default: {}
			t.datetime 		:publish_at
			t.timestamps
		end
		add_index :product_variants, :seq
		add_index :product_variants, :slug, unique: true
		add_index :product_variants, [ :option_name, :option_value ]

		create_table :transactions do |t|
			t.references	:parent_obj, polymorphic: true  # order, refund, etc.
			t.integer		:transaction_type, default: 1 # payment, refund, chargeback
			t.string 		:provider
			t.string 		:reference_code
			t.string 		:customer_profile_reference
			t.string 		:customer_payment_profile_reference
			t.integer 		:amount, default: 0
			t.string 		:currency, default: 'USD'
			t.integer 		:status, default: 1
			t.text			:message, default: nil
			t.hstore 		:properties, default: {}
			t.timestamps
		end
		add_index :transactions, :reference_code

	end
end
