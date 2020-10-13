module BazaarCore
	class OrderOffer < ApplicationRecord
		include BazaarCore::Concerns::MoneyAttributesConcern

		belongs_to :offer
		belongs_to :order
		belongs_to :subscription, required: false, validate: true

		has_many :order_offer_discounts

		money_attributes :subtotal, :price, :tax

		def product
			offer.product
		end

		def self.with_subscription
			where.not( subscription: nil )
		end

		def self.with_subscription_interval_one
			with_subscription.where( subscription_interval: 1 )
		end

		def self.with_subscription_interval_greater_than_one
			with_subscription.where( subscription_interval: 1..Float::INFINITY )
		end

	end
end
