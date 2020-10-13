module BazaarCore
	class OrderOfferDiscount < ApplicationRecord
		belongs_to :order_offer
		belongs_to :discount
		belongs_to :order, required: false, optional: true
		belongs_to :offer, required: false, optional: true
		belongs_to :subscription, required: false, optional: true
		belongs_to :user, required: false, optional: true

		before_save :update_relations


		def update_relations
			self.order = order_offer.order
			self.offer = order_offer.offer
			self.subscription = order_offer.subscription
			self.user = self.order.user
		end

	end
end
