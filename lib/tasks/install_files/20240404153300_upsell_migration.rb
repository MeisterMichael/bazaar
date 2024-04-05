class UpsellMigration < ActiveRecord::Migration[7.1]
  def change

    change_table :bazaar_upsell_offers do |t|
      t.belongs_to 'upsell'
    end

    create_table :bazaar_upsells do |t|
      t.belongs_to "offer"
      t.belongs_to "full_price_offer"
      t.integer "upsell_type", default: nil
      t.integer "status", default: 0
      t.string "title"
      t.string "description"
      t.string "savings"
      t.string "full_price"
      t.string "image_url"
      t.string "disclaimer"
      t.string "supplemental_disclaimer"
      t.timestamps
      t.index ["offer_id"], name: "index_bazaar_upsells_on_offer_id"
      t.index ["status", "offer_id"], name: "index_bazaar_upsells_on_status_and_offer_id"
      t.index ["status"], name: "index_bazaar_upsells_on_status"
      t.index ["upsell_type"], name: "index_bazaar_upsells_on_upsell_type"
    end
  end
end
