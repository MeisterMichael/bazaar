class BazaarOrderOfferDisountMigration < ActiveRecord::Migration[5.1]
	def change
		create_table :bazaar_order_offer_discounts do |t|
			t.belongs_to	:order_offer
			t.belongs_to	:discount
			t.belongs_to	:order
			t.belongs_to	:offer
			t.belongs_to	:subscription
			t.belongs_to	:user
			t.integer			:quantity
			t.timestamps
		end

		add_column :bazaar_discounts, :maximum_units_per_customer, :integer, default: nil
	end
end
