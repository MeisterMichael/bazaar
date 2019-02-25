# desc "Explaining what the task does"
namespace :bazaar do

	task backfill_order_offer_relations: :environment do
		puts "Bazaar::OrderSku.count #{Bazaar::OrderSku.count}"
		puts "Bazaar::OrderOffer.count #{Bazaar::OrderOffer.count}"

		Bazaar::OrderSku.delete_all
		Bazaar::OrderOffer.delete_all

		puts "Bazaar::OrderSku.count #{Bazaar::OrderSku.count}"
		puts "Bazaar::OrderOffer.count #{Bazaar::OrderOffer.count}"
		puts "Bazaar::OrderItem.count #{Bazaar::OrderItem.count}"

		Bazaar::OrderItem.prod.find_each do |order_item|
			order_item.create_offer_relations!
		end
		
		puts "Bazaar::OrderSku.count #{Bazaar::OrderSku.count}"
		puts "Bazaar::OrderOffer.count #{Bazaar::OrderOffer.count}"
	end

	task swell_ecom_to_bazaar_install: :environment do

		prefix = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i

		files = {
			'bazaar_media_controller.rb' => 'app/controllers',
			'bazaar_media_admin_controller.rb' => 'app/controllers',
			'bazaar_media.rb' => 'app/models',
			'20180919154400_bazaar_media_migration.rb' => 'db/migrate',
			'bazaar_media' => 'app/views',
			'bazaar_media_admin' => 'app/views',
		}

		index = 0
		files.each do |source_file_path,destination_path|
			source_file_name = File.basename(source_file_path)
			source = File.join( Gem.loaded_specs["bazaar"].full_gem_path, "lib/tasks/install_files", source_file_path )

			source_file_name = "#{(prefix + index)}_#{source_file_name.gsub(/^[0-9]+_/,"")}" if destination_path == 'db/migrate'

			target = File.join( Rails.root, destination_path, source_file_name )

			FileUtils.cp_r source, target

			puts "#{source}\n-> #{target}\n"
			index += 1
		end

		puts "To complete installation add the following to your routes file before \"get '/:id', to: 'root#show', as: 'root_show'\"\n\nresources :bazaar_media_admin do\nget :preview, on: :member\ndelete :empty_trash, on: :collection\nend\nresources :bazaar_media, only: [:show, :index], path: BazaarMedia.mounted_path\n\n"

	end

	task backfill_geo_address_tags: :environment do
		puts "backfill_geo_address_tags"

		GeoAddress.where( id: Bazaar::Order.select(:shipping_address_id) ).find_each do |geo_address|
			geo_address.tags = geo_address.tags + ['shipping_address']
			geo_address.save

			geo_address.user.update( preferred_shipping_address_id: geo_address.id ) if geo_address.user
		end

		GeoAddress.where( id: Bazaar::Order.select(:billing_address_id) ).find_each do |geo_address|
			geo_address.tags = geo_address.tags + ['billing_address']
			geo_address.save

			geo_address.user.update( preferred_billing_address_id: geo_address.id ) if geo_address.user
		end

	end

	task migrate_all_orders_to_checkout_order: :environment do
		puts "migrate_all_orders_to_checkout_order"

		orders = Bazaar::Order.all
		orders.update_all( type: Bazaar.checkout_order_class_name, source: 'Consumer Checkout' )

	end

	task recalculate_order_rollups: :environment do

		orders = Bazaar::Order.all
		orders.find_each do |order|

			order.shipping = order.order_items.select(&:shipping?).sum(&:subtotal)
			order.tax = order.order_items.select(&:tax?).sum(&:subtotal)
			order.subtotal = order.order_items.select(&:prod?).sum(&:subtotal)
			order.discount = order.order_items.select(&:discount?).sum(&:subtotal)
			order.save

		end

	end


	task migrate_order_status: :environment do

		orders = Bazaar::Order.all
		orders.find_each do |order|

			order.payment_status = 'paid' if order.transactions.positive.present?
			order.payment_status = 'refunded' if order.transactions.refund.present?
			order.payment_status = 'declinded' if order[:status] == -2
			order.payment_status = 'payment_canceled' if order[:status] == -3

			order.fulfillment_status = 'fulfilled' if order.fulfilled_at.present?
			order.fulfillment_status = 'delivered' if order[:status] == 2
			order.fulfillment_status = 'fulfillment_canceled' if order[:status] == -3

			order.status = 'active'

			order.save
		end

	end

	task migrate_subscription_customizations: :environment do
		subscriptions = Bazaar::Subscription.all

		subscriptions.find_each do |subscription|

			subscription.billing_interval_value	= subscription.subscription_plan.billing_interval_value
			subscription.billing_interval_unit	= subscription.subscription_plan.billing_interval_unit
			subscription.trial_price			= subscription.trial_amount / subscription.quantity
			subscription.price					= subscription.amount / subscription.quantity
			subscription.save!

		end
	end

end
