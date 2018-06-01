module SwellEcom

	class TransactionService < ::ApplicationService
		# abstract

		def calculate( obj, args = {} )

			return self.calculate_order( obj, args ) if obj.is_a? Order
			return self.calculate_cart( obj, args ) if obj.is_a? Cart

		end

		def process( order, args = {} )

			throw Exception.new('TransactionService#process is an abstract method')

		end

		def refund( args = {} )

			throw Exception.new('TransactionService#refund is an abstract method')

		end

		def self.parse_credit_card_expiry( expiration )
			return nil if expiration.blank?

			expiration = expiration.gsub(/\s+/,'')

			expiration_parts = expiration.split('/')
			expiration_month = expiration_parts[0]
			expiration_year	 = ( expiration_parts[1].to_i > 100 ? expiration_parts[1] : "#{Time.now.year.to_s[-4,2]}#{expiration_parts[1]}" )
			expiration_time = Time.new( expiration_year, expiration_month ).end_of_month if expiration_parts.count == 2

			expiration_time
		end

		protected

		def calculate_cart( cart, options = {} )

			cart.estimated_total = cart.estimated_tax + cart.estimated_shipping

			cart.cart_items.each do |cart_item|
				cart.estimated_total = cart.estimated_total + cart_item.subtotal
			end

		end

		def calculate_order( order, options = {} )

			order.total = order.order_items.sum(&:subtotal)

		end

	end

end
