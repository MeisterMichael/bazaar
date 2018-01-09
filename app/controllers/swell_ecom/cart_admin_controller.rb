module SwellEcom
	class CartAdminController < SwellMedia::AdminController

		before_filter :get_cart, except: [ :index ]

		def destroy
			authorize( @cart, :admin_destroy? )
			@cart.destroy
			redirect_to cart_admin_index_path
		end

		def edit
			authorize( @cart, :admin_edit? )

		end

		def index
			authorize( SwellEcom::Cart, :admin? )
			sort_by = params[:sort_by] || 'created_at'
			sort_dir = params[:sort_dir] || 'desc'

			@carts = Cart.order( "#{sort_by} #{sort_dir}" )

			if params[:status].present? && params[:status] != 'all'
				@carts = eval "@carts.#{params[:status]}"
			end

			@carts = @carts.page( params[:page] )
		end


		def update
			authorize( @cart, :admin_update? )
			@cart.attributes = cart_params
			@cart.save
			redirect_to :back
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
