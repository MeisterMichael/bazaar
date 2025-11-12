module Bazaar
	class SubProduct < ApplicationRecord

		belongs_to :parent, required: true
		validate	:validate_parent

		def validate_parent
			unless parent.is_a? Bazaar::RootProduct
				errors.add(:parent, "must be a Root Product")
			end
		end
	end
end