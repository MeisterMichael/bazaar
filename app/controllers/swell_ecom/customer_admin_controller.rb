module SwellEcom

	class CustomerAdminController < SwellMedia::AdminController
		helper_method :policy
		before_action :init_search_service, only: [:index]

		def edit
			@user = SwellMedia.registered_user_class.constantize.friendly.find( params[:id] )
			authorize( @user, :customer_admin_edit? )

			@comments = SwellSocial::UserPost.where( parent_obj: @user.id ).order( created_at: :desc ).page( params[:page] ).per(10) if defined?( SwellSocial )

			@subscriptions = SwellEcom::Subscription.where( user: @user ).order( created_at: :desc )
			@orders = SwellEcom::Order.where( user: @user ).order( created_at: :desc )
			# @user_events = SwellMedia::UserEvent.where( guest_session_id: SwellMedia::GuestSession.where( user_id: @user.id ).pluck( :id ) ).order( created_at: :asc ).page(params[:page]).per(50)
			@preferred_address = SwellEcom::GeoAddress.find_by( user: @user, preferred: true )

			@addresses = SwellEcom::GeoAddress.where( user: @user ).order('preferred DESC, created_at DESC')
		end


		def index
			authorize( SwellMedia.registered_user_class.constantize, :customer_admin? )

			sort_by = params[:sort_by] || 'created_at'
			sort_dir = params[:sort_dir] || 'desc'

			filters = ( params[:filters] || {} ).select{ |attribute,value| not( value.nil? ) }
			@users = @search_service.customer_search( params[:q], filters, page: params[:page], order: { sort_by => sort_dir } )

			@order_counts = Hash[*SwellEcom::Order.where( user: @users ).group(:user_id).pluck('user_id, count(id) "orders"').to_a.flatten]
			@active_subscription_counts = Hash[*SwellEcom::Subscription.active.where( user: @users ).group(:user_id).pluck('user_id, count(id) "subscriptions"').to_a.flatten]
			@subscription_counts = Hash[*SwellEcom::Subscription.where( user: @users ).group(:user_id).pluck('user_id, count(id) "subscriptions"').to_a.flatten]
			@geo_addresses = {}
			SwellEcom::GeoAddress.where( user: @users, preferred: true ).each do |geo_address|
				@geo_addresses[ geo_address.user_id ] = geo_address
			end
		end

		def update
			@user = SwellMedia.registered_user_class.constantize.friendly.find( params[:id] )
			authorize( @user, :customer_admin_update? )
			@user.attributes = user_params

			if @user.save
				set_flash "#{@user} updated"
			else
				set_flash "Could not save", :danger, @user
			end
			redirect_to :back
		end

		private
			def user_params
				params.require( :user ).permit( :name, :first_name, :last_name, :email, :short_bio, :bio, :shipping_name, :address1, :address2, :city, :state, :zip, :phone, :role, :status )
			end

			def init_search_service
				@search_service = EcomSearchService.new
			end

	end

end
