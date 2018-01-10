# a list of tax codes
# https://taxcloud.net/tic/

module SwellEcom

	class DiscountService

		def initialize( args = {} )
		end

		def calculate( obj, args = {} )

			return self.calculate_order( obj ) if obj.is_a? Order
			return self.calculate_cart( obj ) if obj.is_a? Cart

		end

		protected

		def calculate_cart( cart )

		end

		def calculate_order( order )

		end

	end

end
