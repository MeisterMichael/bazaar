class OfferStrikethroughPriceMigration < ActiveRecord::Migration[7.1]
  def change
    change_table :bazaar_offers do |t|
      t.integer "suggested_price", default: nil
    end
  end
end
