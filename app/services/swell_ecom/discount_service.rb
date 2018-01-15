# a list of tax codes
# https://taxcloud.net/tic/

module SwellEcom

	class DiscountService

		def initialize( args = {} )
		end

		def calculate_pre_tax( obj, args = {} )

			return self.calculate_pre_tax_order( obj ) if obj.is_a? Order
			return self.calculate_pre_tax_cart( obj ) if obj.is_a? Cart

		end

		def calculate_post_tax( obj, args = {} )

			return self.calculate_post_tax_order( obj ) if obj.is_a? Order
			return self.calculate_post_tax_cart( obj ) if obj.is_a? Cart

		end

		protected

		def calculate_post_tax_cart( cart )
			# @todo
		end

		def calculate_post_tax_order( order )
			# @todo
		end

		def calculate_pre_tax_cart( cart )
			# @todo
		end

		def calculate_pre_tax_order( order )
			# @todo
		end

	end

end
