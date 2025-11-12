module Bazaar
	class RootProduct < ApplicationRecord
		validate	:validate_parent
		has_many :sub_products, class_name: 'Bazaar::SubProduct', foreign_key: :parent_id

		def validate_parent
			unless parent_id.present?
				errors.add(:parent_id, "must be blank for a Root Product")
			end
		end
	end
end