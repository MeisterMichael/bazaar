class UpsellOfferDisclaimerMigration < ActiveRecord::Migration[7.1]
  def change

    change_table :bazaar_upsell_offers do |t|
      t.string :disclaimer, default: nil
      t.string :supplemental_disclaimer, default: nil
    end
  end
end
