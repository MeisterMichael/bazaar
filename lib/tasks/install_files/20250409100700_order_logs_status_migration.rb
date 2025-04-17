class OrderLogsStatusMigration < ActiveRecord::Migration[7.1]
	def change

		change_table :bazaar_order_logs do |t|
			t.integer		:log_type, default: 0
			t.index [:log_type,:source, :subject]
			t.index [:log_type,:subject]
		end

	end
end
