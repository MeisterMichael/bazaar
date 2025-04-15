module Bazaar
	class SubscriptionPeriod < ApplicationRecord
		include Bazaar::Concerns::MoneyAttributesConcern

		belongs_to	:subscription
		belongs_to	:order, required: false, validate: true

		has_many :order_offers
		has_many :orders, through: :order_offers

		enum status: { 'failed' => -100, 'pending' => 0, 'success' => 100 }

	end
end
