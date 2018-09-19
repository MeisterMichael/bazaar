class SwellEcomToBazaarMigration < ActiveRecord::Migration[5.1]
	def change

		rename_index :discount_items, :index_discount_items_on_applies_to_type_and_applies_to_id, :index_discount_items_on_applies_to
		rename_index :wholesale_items, :index_wholesale_items_on_wholesale_profile_id_and_min_quantity, :index_wholesale_items_on_profile_id_and_min_qty

		rename_table :cart_items, :bazaar_cart_items
		rename_table :carts, :bazaar_carts
		rename_table :collection_items, :bazaar_collection_items
		rename_table :collections, :bazaar_collections
		rename_table :discount_items, :bazaar_discount_items
		rename_table :discount_users, :bazaar_discount_users
		rename_table :discounts, :bazaar_discounts
		rename_table :order_items, :bazaar_order_items
		rename_table :orders, :bazaar_orders
		rename_table :product_variants, :bazaar_product_variants
		rename_table :products, :bazaar_products
		rename_table :shipping_carrier_services, :bazaar_shipping_carrier_services
		rename_table :shipping_options, :bazaar_shipping_options
		rename_table :subscription_plans, :bazaar_subscription_plans
		rename_table :subscriptions, :bazaar_subscriptions
		rename_table :transactions, :bazaar_transactions
		rename_table :wholesale_items, :bazaar_wholesale_items
		rename_table :wholesale_profiles, :bazaar_wholesale_profiles

	end
end
