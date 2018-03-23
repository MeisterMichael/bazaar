module SwellEcom
	class OrderItem < ApplicationRecord
		self.table_name = 'order_items'
		include SwellEcom::Concerns::MoneyAttributesConcern

		enum order_item_type: { 'prod' => 1, 'tax' => 2, 'shipping' => 3, 'discount' => 4 }

		belongs_to :item, polymorphic: true, required: false
		belongs_to :order

		belongs_to :subscription, required: false, validate: true

		money_attributes :subtotal, :price

		def package_item
			package_item = self.item
			package_item = package_item.subscription_plan if package_item.is_a? SwellEcom::Subscription
			package_item
		end

		def package_shape
			self.properties['package_shape'] || package_item.package_shape
		end

		def package_weight
			return self.properties['package_weight'].to_f if self.properties['package_weight']
			package_item.package_weight
		end

		def package_length
			return self.properties['package_length'].to_f if self.properties['package_length']
			package_item.package_length
		end

		def package_width
			return self.properties['package_width'].to_f if self.properties['package_width']
			package_item.package_width
		end

		def package_height
			return self.properties['package_height'].to_f if self.properties['package_height']
			package_item.package_height
		end




	end
end
