module SwellEcom
	class CartItem < ApplicationRecord
		self.table_name = 'cart_items'
		include SwellEcom::Concerns::MoneyAttributesConcern

		belongs_to 	:cart
		belongs_to 	:item, polymorphic: true, required: false

		money_attributes :subtotal, :price


		delegate :to_s, to: :item

		def package_item
			package_item = self.item
			package_item = package_item.subscription_plan if package_item.is_a? SwellEcom::Subscription
			package_item
		end

		def package_shape
			package_item.package_shape
		end

		def package_weight
			package_item.package_weight
		end

		def package_length
			package_item.package_length
		end

		def package_width
			package_item.package_width
		end

		def package_height
			package_item.package_height
		end



	end
end
