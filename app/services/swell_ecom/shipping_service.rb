module SwellEcom

	class ShippingService

		def initialize( args = {} )
		end

		def calculate( obj )

			return self.calculate_order( obj ) if obj.is_a? Order
			return self.calculate_cart( obj ) if obj.is_a? Cart

		end


		protected

		def self.calculate_cart( cart )

			cart.update estimated_shipping: 0

		end

		def self.calculate_order( order )

			# order.order_items.new item: nil, amount: 1000, label: 'Shipping', order_item_type: 'shipping', tax_code: '11000'

=begin
			Taxability Information Code: 11010
			Transportation, shipping, postage, and similar charges.
			IMPORTANT: TIC 11010 should only be used if your are charging your customer your actual shipping cost as can be demonstrated by your invoice from your shipping provider.
			If you offer "Flat Rate Shipping"	(regardless of your actual shipping costs), or if you markup your shipping charges (charing your customers more than your actual shipping cost), you should use Shipping & Handling TIC 11000.
=end

			return

		end

	end

end
