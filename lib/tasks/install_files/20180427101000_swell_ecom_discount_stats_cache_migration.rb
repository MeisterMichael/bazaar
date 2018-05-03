class SwellEcomDiscountStatsCacheMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :discounts, :cached_uses, :integer, default: 0

	end
end
