class BazaarOffersMigration < ActiveRecord::Migration[5.1]
	def change
		create_table :bazaar_offers do |t|
			t.integer			:status, default: 1
			t.integer			:availability, default: 1
			t.string			:title
			t.string			:avatar
			t.string			:code
			t.string			:tax_code, default: "00000"
			t.text				:description
			t.text				:cart_description
			t.timestamps
		end

		create_table :bazaar_order_offers do |t|
			t.belongs_to	:offer
			t.belongs_to	:order
			t.belongs_to	:subscription
			t.integer			:subscription_interval, default: 1
			t.string			:title
			t.string			:tax_code
			t.integer			:price
			t.integer			:quantity
			t.integer			:subtotal
			t.timestamps
		end

		create_table :bazaar_order_skus do |t|
			t.belongs_to	:sku
			t.belongs_to	:order
			t.integer			:quantity
			t.timestamps
		end

		add_column :bazaar_products, :offer_id, :bigint, default: nil
		add_index :bazaar_products, :offer_id

		add_column :bazaar_subscription_plans, :offer_id, :bigint, default: nil
		add_index :bazaar_subscription_plans, :offer_id

		add_column :bazaar_subscriptions, :offer_id, :bigint, default: nil
		add_index :bazaar_subscriptions, :offer_id

		reversible do |dir|
			dir.up do
				Bazaar::Product.all.each do |product|
					product.update_offer!

					Bazaar::OfferSku.where( parent_obj: product ).update_all( parent_obj_id: product.offer.id, parent_obj_type: product.offer.class.base_class.name )
					product.update_prices!
					product.update_schedule!

				end

				Bazaar::SubscriptionPlan.all.each do |plan|
					plan.update_offer!

					Bazaar::OfferSku.where( parent_obj: plan ).update_all( parent_obj_id: plan.offer.id, parent_obj_type: plan.offer.class.base_class.name )
					plan.update_prices!
					plan.update_schedule!

					Bazaar::Subscription.where( subscription_plan_id: plan.id ).update_all( offer_id: plan.offer.id )

				end
			end

			dir.down do
				Bazaar::Product.all.each do |product|

					Bazaar::OfferSku.where( parent_obj: product.offer ).update_all( parent_obj_id: product.id, parent_obj_type: product.class.base_class.name )
					product.update_prices!
					product.update_schedule!

				end

				Bazaar::SubscriptionPlan.all.each do |plan|

					Bazaar::OfferSku.where( parent_obj: plan.offer ).update_all( parent_obj_id: plan.id, parent_obj_type: plan.class.base_class.name )
					plan.update_prices!
					plan.update_schedule!

				end
			end
		end
	end

end
