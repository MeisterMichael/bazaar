class SwellEcomOrderRefactorMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :orders, :type, :string, default: nil
		add_column :orders, :source, :string, default: 'checkout'
		add_column :orders, :source_url, :text, default: nil
		add_index  :orders, [ :type, :status, :payment_status ]
		add_index  :orders, [ :source, :status, :payment_status ]

	end
end
