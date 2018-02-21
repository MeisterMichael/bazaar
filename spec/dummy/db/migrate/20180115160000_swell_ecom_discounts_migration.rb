class SwellEcomDiscountsMigration < ActiveRecord::Migration[5.1]
	def change

		create_table :discounts do |t|
			t.string 		:title
			t.text 			:description
			t.string 		:code
			t.integer		:status, 	default: 0
			t.datetime		:start_at
			t.datetime		:end_at, default: nil
			t.integer		:availability, default: 1 # anyone, selected_users
			t.integer		:minimum_prod_subtotal, default: 0
			t.integer		:minimum_shipping_subtotal, default: 0
			t.integer		:minimum_tax_subtotal, default: 0
			t.integer		:limit_per_customer, default: nil
			t.integer		:limit_global, default: nil
			t.timestamps
		end

		create_table :discount_items do |t|
			t.references 	:discount
			t.references 	:applies_to, polymorphic: true, default: nil # nil => everything, product, subscription_plans, categories, ...
			t.integer		:order_item_type, default: 1 # prod, shipping, taxes
			t.integer		:minimum_orders, default: 0
			t.integer		:maximum_orders, default: 1
			t.string 		:currency, default: 'USD'
			t.integer		:discount_amount
			t.integer		:discount_type, default: 1 # percent, fixed
			t.timestamps
		end

		create_table :discount_users do |t|
			t.belongs_to 	:discount
			t.belongs_to	:user
		end

		add_column :subscriptions, :discount_id, :integer, default: nil

	end
end
