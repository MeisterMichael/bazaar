class SwellEcomDiscountOwnerMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :discounts, :user_id, :integer, default: nil
		add_index :discounts, [ :user_id, :status, :title ]
		add_index :discounts, [ :user_id, :status, :code ]
		add_index :discounts, [ :user_id, :status, :start_at ]
		add_index :discounts, [ :user_id, :status, :end_at ]

		add_column :discounts, :type, :string
		add_index :discounts, [ :type, :id ]
	end
end
