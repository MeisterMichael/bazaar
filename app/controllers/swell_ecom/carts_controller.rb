module SwellEcom
	class CartsController < ApplicationController
		# really just to show the user's cart

		def show
			@cart = Cart.find_by( id: cookies[:cart] )
		end

		def update
			@cart = cookies.permanent.signed[:cart]
		end

	end
end