module SwellEcom

	class ShippingService

		def self.calculate( order )

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
