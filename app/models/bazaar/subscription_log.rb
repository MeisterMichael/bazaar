module Bazaar
	class SubscriptionLog < ApplicationRecord

		belongs_to :subscription, required: false
		belongs_to :subscription_period, required: false
		belongs_to :subscription_offer, required: false
		belongs_to :order, required: false
		belongs_to :order_offer, required: false

	end
end
