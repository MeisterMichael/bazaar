module SwellEcom
	class ProductVariant < ActiveRecord::Base

		self.table_name = 'product_variants'
		
		enum status: { 'draft' => 0, 'active' => 1, 'archive' => 2, 'trash' => 3 }


		before_save :set_defaults

		belongs_to :product 
		
		include FriendlyId
		friendly_id :title, use: [ :slugged, :history ]


		def self.published
			self.active
		end


		def url
			self.product.url
		end


		private
			def set_defaults
				if self.title.blank?
					self.title = "#{self.product.title} | #{self.option_name}: #{self.option_value}"
				end
				self.price = self.product.price	unless self.price > 0
				self.shipping_price = self.product.shipping_price unless self.shipping_price > 0
				self.description ||= self.product.description
				self.avatar ||= self.product.avatar
				self.publish_at ||= self.product.publish_at
			end
	end

end