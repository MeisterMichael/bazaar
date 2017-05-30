module SwellEcom
	class CartItem < ActiveRecord::Base
		self.table_name = 'cart_items'

		belongs_to 	:cart 
		belongs_to 	:item, polymorphic: true

		
	end
end