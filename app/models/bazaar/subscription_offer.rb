module Bazaar
	class SubscriptionOffer < ApplicationRecord
		include Bazaar::Concerns::MoneyAttributesConcern

		belongs_to	:subscription
		belongs_to	:offer

		has_many :order_offers
		has_many :orders, through: :order_offers

		enum status: { 'canceled' => -100, 'draft' => 0, 'active' => 100 }

	end
end
