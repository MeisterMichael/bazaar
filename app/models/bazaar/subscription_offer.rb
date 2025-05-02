module Bazaar
	class SubscriptionOffer < ApplicationRecord
		include Bazaar::Concerns::MoneyAttributesConcern

		belongs_to	:subscription
		belongs_to	:offer

		has_many :order_offers
		has_many :orders, through: :order_offers

		has_many :subscription_logs

		enum status: { 'trash' => -200, 'canceled' => -100, 'draft' => 0, 'active' => 100 }



		def next_offer_interval( args = {} )
			orders = Bazaar::Order.where( status: args[:statuses] ) if args[:statuses]
			orders ||= Bazaar::Order.positive_status

			( Bazaar::OrderOffer.where( subscription_offer: self ).joins(:order).merge( orders ).maximum(:offer_interval) || 0 ) + 1
		end
	end
end
