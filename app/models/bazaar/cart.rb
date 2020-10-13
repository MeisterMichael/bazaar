module Bazaar
	class Cart < ApplicationRecord
		include Bazaar::CartSearchable if (Bazaar::CartSearchable rescue nil)

		enum status: { 'active' => 1, 'init_checkout' => 2, 'success' => 3 }

		has_many :cart_offers, dependent: :destroy

		belongs_to :order, required: false
		belongs_to :user, required: false

		def to_s
			"Cart \##{self.id}"
		end

	end
end
