class OfferDisclaimerMigration < ActiveRecord::Migration[7.1]
  def change
    change_table :bazaar_offers do |t|
      t.text :disclaimer, default: nil
    end
  end
end
