class SwellEcomSubscriptionFailMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :subscriptions, :failed_at, :datetime, default: nil
		add_column :subscriptions, :failed_message, :text, default: nil
		add_column :subscriptions, :failed_attempts, :integer, default: 0

	end
end
