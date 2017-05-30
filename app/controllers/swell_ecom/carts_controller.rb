module SwellEcom
	class CartsController < ApplicationController
		# really just to show the user's cart

		before_filter :get_cart

		def show
			
		end

		def update
			
		end

		private
			def get_cart
				@cart = Cart.find_by( id: session[:cart_id] )
			end

	end
end