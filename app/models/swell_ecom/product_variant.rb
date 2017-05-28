module SwellEcom
	class ProductVariant < ActiveRecord::Base

		self.table_name = 'product_variants'

		before_save :set_defaults

		belongs_to :product 
		
		include FriendlyId
		friendly_id :slugger, use: [ :slugged, :history ]





		def slugger
			slg = self.product.friendly_id
			self.options.each{ |opt| slg += "_#{opt[1]}" }
			return slg
		end


		private
			def set_defaults
				if self.title.blank?
					self.title = self.product.title
					self.options.each{ |opt| self.title += " | #{opt[0]} #{opt[1]}" }
				end
				self.shipping_price ||= self.product.shipping_price
				self.price ||= self.product.price			
				self.description ||= self.product.description
				self.publish_at ||= self.product.publish_at
			end
	end

end