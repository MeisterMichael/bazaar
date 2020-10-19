module BazaarCore
	class ProductVariant < ApplicationRecord


		include FriendlyId
		include BazaarCore::Concerns::MoneyAttributesConcern

		enum status: { 'draft' => 0, 'active' => 1, 'archive' => 2, 'trash' => 3 }
		enum availability: { 'backorder' => -1, 'pre_order' => 0, 'open_availability' => 1 }
		enum package_shape: { 'no_shape' => 0, 'letter' => 1, 'box' => 2, 'cylinder' => 3 }

		before_save :set_defaults

		belongs_to	:product

		money_attributes :price, :shipping_price, :purchase_price
		friendly_id :title, use: [ :slugged, :history ]


		def self.published
			self.active
		end

		def purchase_price
			self.price
		end

		def option_title( opts={} )
			separator = opts[:separator] || ': '
			return "#{self.option_name}#{separator}#{self.option_value}"
		end

		def sku
			"prod-#{self.product.slug}-#{self.slug}"
		end

		def tax_code
			self.product.tax_code
		end

		def url
			self.product.url
		end

		def page_event_data
			self.product.page_event_data.merge( variant: self.title )
		end


		private
			def set_defaults
				if self.title.blank?
					self.title = "#{self.product.title} #{self.option_title}"
					#self.title = "#{self.product.title} | #{self.option_name}: #{self.option_value}"
				end
				self.price = self.product.price	unless self.price > 0
				self.shipping_price = self.product.shipping_price unless self.shipping_price > 0
				self.description ||= self.product.description
				self.avatar ||= self.product.avatar
				self.publish_at ||= self.product.publish_at
			end
	end

end
