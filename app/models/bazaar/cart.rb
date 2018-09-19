module Bazaar
	class Cart < ApplicationRecord
		

		enum status: { 'active' => 1, 'init_checkout' => 2, 'success' => 3 }

		has_many :cart_items, dependent: :destroy

		belongs_to :order, required: false
		belongs_to :user, required: false

		def to_s
			"Cart \##{self.id}"
		end

	end
end
