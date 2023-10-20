module Bazaar
	class CartAdminController < Bazaar::EcomAdminController

		before_action :get_cart, except: [ :index ]

		def destroy
			authorize( @cart )
			@cart.destroy
			redirect_to cart_admin_index_path
		end

		def edit
			authorize( @cart )
			set_page_meta( title: "Cart" )
		end

		def index
			authorize( Bazaar::Cart )
			sort_by = params[:sort_by] || 'created_at'
			sort_dir = params[:sort_dir] || 'desc'

			@carts = Cart.order( Arel.sql("#{sort_by} #{sort_dir}") )

			if params[:status].present? && params[:status] != 'all'
				@carts = eval "@carts.#{params[:status]}"
			end

			@carts = @carts.page( params[:page] )

			set_page_meta( title: "Carts" )
		end


		def update
			authorize( @cart )
			@cart.attributes = cart_params
			@cart.save
			redirect_back fallback_location: '/admin'
		end

		private
			def cart_params
				params.require( :cart ).permit( :status )
			end

			def get_cart
				@cart = Cart.find_by( id: params[:id] )
			end

	end
end
