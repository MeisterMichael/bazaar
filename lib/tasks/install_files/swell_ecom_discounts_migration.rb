class SwellEcomSubscriptionsMigration < ActiveRecord::Migration
	def change

		# Simple
		create_table :discounts do |t|
			t.string 		:code
			t.integer		:status, 	default: 0

			t.datetime		:start_at
			t.datetime		:end_at, default: nil

			t.integer		:applies_to, default: 1 # entire_order, selected_items, selected_categories
			t.integer		:availability, default: 1 # anyone, selected_users

			t.integer		:minimum_prod_subtotal, default: nil
			t.integer		:minimum_shipping_subtotal, default: nil

			t.string 		:currency, default: 'USD'
			t.integer		:prod_discount_amount
			t.integer		:prod_discount_type, default: 1 # percent, fixed
			t.integer		:shipping_discount_amount
			t.integer		:shipping_discount_type, default: 1 # percent, fixed

			t.integer		:limit_per_customer, default: nil
			t.integer		:limit_global, default: nil



			t.timestamps
		end

		# VERSUS
		#
		# # Comprehensive
		# create_table :discounts do |t|
		# 	t.string 		:code
		# 	t.integer		:status, 	default: 0
		#
		# 	t.datetime		:start_at
		# 	t.datetime		:end_at, default: nil
		#
		# 	t.integer		:availability, default: 1 # anyone, selected_users
		#
		# 	t.integer		:minimum_prod_subtotal, default: nil
		# 	t.integer		:minimum_shipping_subtotal, default: nil
		#
		# 	t.integer		:limit_per_customer, default: nil
		# 	t.integer		:limit_global, default: nil
		#
		# 	t.timestamps
		# end
		#
		# create_table :discount_items do |t|
		# 	t.belongs_to 	:discount
		# 	t.integer		:applies_to, default: 1 # entire_order, selected_items, selected_categories
		# 	t.integer		:order_item_type, default: 1 # prod, shipping
		# 	t.string 		:currency, default: 'USD'
		# 	t.integer		:discount_amount
		# 	t.integer		:discount_type, default: 1 # percent, fixed
		# 	t.timestamps
		# end


	end
end
