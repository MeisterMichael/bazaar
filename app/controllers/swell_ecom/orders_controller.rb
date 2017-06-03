module SwellEcom
	class OrdersController < ApplicationController

		def thank_you
			@order = Order.find_by( code: params[:id] )
		end

	end
end
