class SwellEcomSubscriptionsMigration < ActiveRecord::Migration
	def change

		create_table :subscription do |t|
			t.references	:user
			t.references	:plan
			t.references	:order_item
			t.integer		:quantity, default: 1
			t.string 		:code

			t.datetime		:start_at
			t.datetime		:end_at, default: nil

			t.datetime		:trial_start_at, default: nil
			t.datetime		:trial_end_at, default: nil

			t.datetime		:current_period_start_at
			t.datetime		:current_period_end_at
			t.datetime		:next_charged_at

			t.integer		:amount
			t.integer		:trial_amount
			t.string 		:currency, default: 'USD'

			t.string		:interval, default: 'month' #day, week, month, year
			t.integer		:interval_value, default: 1

			t.string		:provider
			t.string		:provider_reference
			t.string		:provider_customer_profile_reference
			t.string		:provider_customer_payment_profile_reference

			t.timestamps
		end

		create_table :subscription_plans do |t|

			t.integer 		:recurring_price # cents
			t.string		:recurring_interval, default: 'month' #day, week, month, year
			t.integer		:recurring_interval_value, default: 1
			t.integer		:recurring_max_intervals, default: nil # for fixed length subscription
			t.string		:recurring_statement_descriptor

			t.integer 		:trial_price, default: 0 # cents, recurring trial price
			t.string		:trial_interval, default: 'month' #day, week, month, year
			t.integer		:trial_interval_value, default: 1
			t.integer		:trial_max_intervals, default: 0
			t.string		:trial_statement_descriptor # a null value default to statement_descriptor

			t.integer		:subscription_plan_type, default: 1 # physical, digital

			# copied products:
			t.references 	:category
			t.string 		:title
			t.string		:caption
			t.string 		:slug
			t.string 		:avatar
			# t.integer		:default_product_type, default: 1 # physical, digital
			# t.string 		:fulfilled_by, default: 'self' # self, download, amazon, printful
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
			t.string		:tax_code, default: nil
			t.hstore		:properties, default: {}
			t.timestamps
		end
		add_index :subscription_plans, :tags, using: 'gin'
		add_index :subscription_plans, :category_id
		add_index :subscription_plans, :slug, unique: true
		add_index :subscription_plans, :status


		add_column :orders, :generated_by, :integer, default: 1

	end
end
