class SwellEcomSubscriptionsMigration < ActiveRecord::Migration[5.1]
	def change

		create_table :subscriptions do |t|
			t.references	:user
			t.references	:subscription_plan
			t.references 	:billing_address
			t.references 	:shipping_address
			t.integer		:quantity, default: 1
			t.string 		:code
			t.integer		:status, 	default: 0

			t.datetime		:start_at
			t.datetime		:end_at, default: nil
			t.datetime		:canceled_at, default: nil

			t.datetime		:trial_start_at, default: nil
			t.datetime		:trial_end_at, default: nil

			t.datetime		:current_period_start_at
			t.datetime		:current_period_end_at
			t.datetime		:next_charged_at

			t.integer		:amount
			t.integer		:trial_amount
			t.string 		:currency, default: 'USD'

			t.string		:provider
			t.string		:provider_reference
			t.string		:provider_customer_profile_reference
			t.string		:provider_customer_payment_profile_reference

			t.datetime		:payment_profile_expires_at, default: nil

			t.timestamps
		end

		create_table :subscription_plans do |t|

			t.string		:billing_interval_unit, default: 'months' # or days
			t.integer		:billing_interval_value, default: 1
			t.string		:billing_statement_descriptor

			t.integer 		:trial_price, default: 0 # cents, recurring trial price
			t.string		:trial_interval_unit, default: 'month' #day
			t.integer		:trial_interval_value, default: 1
			t.integer		:trial_max_intervals, default: 0
			t.string		:trial_statement_descriptor # a null value default to statement_descriptor

			t.integer		:subscription_plan_type, default: 1 # physical, digital

			# copied products:
			t.string		:title
			t.integer		:seq,             default: 1
			t.string		:slug
			t.string		:avatar
			t.integer		:status,          default: 0
			t.text			:description
			t.text			:content
			t.datetime		:publish_at
			t.integer		:price,           default: 0
			t.integer		:shipping_price,  default: 0
			t.string		:currency,        default: "USD"
			t.hstore		:properties,      default: {}
			t.datetime		:created_at
			t.datetime		:updated_at
			t.string		:tax_code,        default: "00000"

			t.timestamps
		end
		add_index :subscription_plans, :slug, unique: true
		add_index :subscription_plans, :status

		add_column :order_items, :subscription_id, :integer
		add_index :order_items, [ :subscription_id ]


		add_column :orders, :generated_by, :integer, default: 1
		add_column :orders, :parent_id, :integer, default: nil
		add_column :orders, :parent_type, :string, default: nil
		change_column :orders, :status, :integer, default: 2
		add_index :orders, [ :parent_type, :parent_id ]
		add_index :orders, :status

	end
end
