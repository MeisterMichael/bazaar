# a list of tax codes
# https://taxcloud.net/tic/

module Bazaar

	class TaxService < ::ApplicationService

		def initialize( args = {} )
		end

		def calculate( obj, args = {} )

			return self.calculate_order( obj ) if obj.is_a? Order
			return self.calculate_cart( obj ) if obj.is_a? Cart
			return false

		end

		def recalculate( obj, args = {} )

			return self.calculate_order( obj ) if obj.is_a? Order
			return self.calculate_cart( obj ) if obj.is_a? Cart
			return false

		end

		protected

		def calculate_cart( cart )
			return # @todo deal with tax calculations later.... punted
		end

		def calculate_order( order )
			return # @todo deal with tax calculations later.... punted
		end

	end

end
