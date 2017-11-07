module SwellEcom

	class TransactionService
		# abstract

		def calculate( obj, args = {} )

			return self.calculate_order( obj ) if obj.is_a? Order
			return self.calculate_cart( obj ) if obj.is_a? Cart

		end

		def process( order, args = {} )

			throw Exception.new('TransactionService#process is an abstract method')

		end

		def refund( args = {} )

			throw Exception.new('TransactionService#refund is an abstract method')

		end

		protected

		def calculate_cart( cart )

			cart.estimated_total = cart.estimated_tax + cart.estimated_shipping

			cart.cart_items.each do |cart_item|
				cart.estimated_total = cart.estimated_total + cart_item.subtotal
			end

		end

		def calculate_order( order )

			order.total = 0

			order.order_items.each do |order_item|
				order.total = order.total + order_item.subtotal
			end

		end

	end

end
