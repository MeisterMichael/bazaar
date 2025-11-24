module Bazaar

	class ProductService < ::ApplicationService

		def before_save( product, args = {} )

			change_recurring_offer = false
			change_non_recurring_offer = false

			# Change the Non-Recurring Offer, with the strikethrough_price
			change_non_recurring_offer = { initial_price: product.listing_strikethrough_price } if product.single_plus_subscription? && (product.listing_strikethrough_price_changed? || product.listing_sku_id_changed? || product.listing_offer_mode_changed?)

			# Change the Non-Recurring Offer, with the from_price
			change_non_recurring_offer = { initial_price: product.listing_from_price } if product.single_only? && (product.listing_from_price_changed? || product.listing_sku_id_changed? || product.listing_offer_mode_changed?)

			# Change the Recurring Offer
			if ((product.single_plus_subscription? || product.subscription_only?) && (product.listing_from_price_changed? || product.listing_renewal_price_changed? || product.listing_sku_id_changed? || product.listing_recurring_sku_changed? || product.listing_offer_mode_changed?))
				change_recurring_offer = {
					initial_price: product.listing_from_price,
					recurring_price: product.listing_renewal_price,
				}
			end

			if change_non_recurring_offer
				offer_code = "#{product.slug}-#{change_non_recurring_offer[:initial_price]}-product-generated"
				offer = Bazaar::Offer.where( code: offer_code ).create_with(
					product: product,
					title: "#{product.title} #{ActionController::Base.helpers.number_to_currency(change_non_recurring_offer[:initial_price]/100.0)} (Product Generated)",
					status: 'active',
				).first_or_initialize

				unless offer.persisted?
					offer.offer_schedules.new( start_interval: 1, max_intervals: 1, interval_unit: 'days', interval_value: 28 , status: 'active' )
					offer.offer_prices.new( start_interval: 1, max_intervals: 1, price: change_non_recurring_offer[:initial_price], status: 'active' )
					offer.offer_skus.new( start_interval: 1, max_intervals: 1, sku: product.listing_sku, status: 'active' )
				end

				puts "listing_non_recurring_offer"
				puts offer.to_json
				offer.save!
				product.listing_non_recurring_offer = offer
			end

			if change_recurring_offer
				offer_code = "#{product.slug}-auto-renew-#{change_recurring_offer[:initial_price]}-#{change_recurring_offer[:recurring_price]}-product-generated"
				offer = Bazaar::Offer.where( code: offer_code ).create_with(
					product: product,
					title: "#{product.title} Auto Renew #{ActionController::Base.helpers.number_to_currency(change_recurring_offer[:initial_price]/100.0)} / #{ActionController::Base.helpers.number_to_currency(change_recurring_offer[:recurring_price]/100.0)} (Product Generated)",
					status: 'active',
				).first_or_initialize

				unless offer.persisted?
					offer.offer_schedules.new( start_interval: 1, max_intervals: nil, interval_unit: 'days', interval_value: 28 , status: 'active' )
					offer.offer_prices.new( start_interval: 1, max_intervals: 1, price: change_recurring_offer[:initial_price], status: 'active' )
					offer.offer_prices.new( start_interval: 2, max_intervals: nil, price: change_recurring_offer[:recurring_price], status: 'active' )
					offer.offer_skus.new( start_interval: 1, max_intervals: ( product.listing_recurring_sku.present? ? 1 : nil ), sku: product.listing_sku, status: 'active' )
					offer.offer_skus.new( start_interval: 3, max_intervals: nil, sku: product.listing_recurring_sku, status: 'active' ) if product.listing_recurring_sku.present?
				end

				puts "listing_recurring_offer"
				puts offer.to_json
				offer.save!
				product.listing_recurring_offer = offer

			end

		end

	end

end