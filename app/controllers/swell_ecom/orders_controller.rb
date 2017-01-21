module SwellEcom
	class OrdersController < ApplicationController

		def show
			@order = Order.find_by( code: params[:id] )
		end

	end
end
