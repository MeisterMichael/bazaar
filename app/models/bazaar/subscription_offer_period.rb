module Bazaar
	class SubscriptionOfferPeriod

		attr_accessor :subscription_period
		attr_accessor :subscription_offer
		attr_accessor :subscription
		attr_accessor :offer
		attr_accessor :order
		attr_accessor :order_offer
		attr_accessor :offer_interval
		attr_accessor :subscription_interval

		def order_offers
			subscription_offer.order_offers.where( offer_interval: offer_interval )
		end

		def orders
			Bazaar::Order.where( id: order_offers.select(:order_id) )
		end

		def subscription_logs
			subscription_offer.subscription_logs.where( offer_interval: offer_interval )
		end

	end
end
