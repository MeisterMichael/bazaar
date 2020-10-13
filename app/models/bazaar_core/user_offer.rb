module Bazaar
	class UserOffer < ApplicationRecord

		belongs_to :user
		belongs_to :offer

		def title
			self.offer.title
		end

	end
end
