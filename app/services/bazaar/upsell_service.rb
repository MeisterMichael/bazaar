module Bazaar
	class UpsellService

		def find_at_checkout_offers_for_order( order, options = {} )
			find_offers_for_order( order, options.merge( upsell_type: 'at_checkout' ) )
		end

		def find_exit_checkout_offers_for_order( order, options = {} )
			find_offers_for_order( order, options.merge( upsell_type: 'exit_checkout' ) )
		end

		def find_post_sale_offers_for_order( order, options = {} )
			find_offers_for_order( order, options.merge( upsell_type: 'post_sale' ) )
		end

		def find_offers_for_order( order, options = {} )
			offers = order.order_offers.collect(&:offer)
			find_offers_for_offers( offers, options )
		end

		def find_offers_for_cart( cart, options = {} )
			offers = @cart.cart_offers.collect(&:offer)
			find_offers_for_offers( offers, options )
		end

		def find_offers_for_offers( offers, options = {} )
			products = offers.collect(&:product).uniq
			upsell_offers = Bazaar::UpsellOffer.active.joins(:offer)

			# limit upsell_offers to the type provided (otherwise all types allowed)
			upsell_offers = upsell_offers.where( upsell_type: options[:upsell_type] ) if options[:upsell_type].present?

			# limit upsell_offers to those from products/offers provided
			upsell_offers = upsell_offers.where( src_product: products, src_offer: nil ).or( upsell_offers.where( src_offer: offers ) )

			offers = Bazaar::Offer.all

			# exclude offers for products that are already in list
			offers = offers.where.not( product: products )

			# exclude offers with skus that are already in the list
			# offers = offers.where.not( id: Bazaar::OfferSku.where( sku: offers.collect(&:skus).flatten.uniq ).select(:offer_id) )

			# limit upsell_offers to qualified offers
			upsell_offers = upsell_offers.merge( offers )

			upsell_offers.order(Arel.sql('RANDOM()'))
		end

		def has_at_checkout_offers_for_order?( order, options = {} )
			find_offers_for_order( order, options.merge( upsell_type: 'at_checkout' ) ).present?
		end

		def has_post_sale_offers_for_order?( order, options = {} )
			find_offers_for_order( order, options.merge( upsell_type: 'post_sale' ) ).present?
		end

	end
end
