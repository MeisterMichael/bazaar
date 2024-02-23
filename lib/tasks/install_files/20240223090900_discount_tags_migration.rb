class DiscountTagsMigration < ActiveRecord::Migration[7.1]
  def change
    change_table :bazaar_discounts do |t|
      t.string "tags", default: [], array: true
    end

    change_table :bazaar_discount_items do |t|
      t.string "tags", default: [], array: true
    end
  end
end
