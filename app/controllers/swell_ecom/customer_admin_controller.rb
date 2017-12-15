module SwellEcom

	class CustomerAdminController < SwellMedia::AdminController

		def edit
			@user = SwellMedia.registered_user_class.constantize.friendly.find( params[:id] )

			@comments = SwellSocial::UserPost.where( parent_obj: @user.id ).order( created_at: :desc ).page( params[:page] ).per(10) if defined?( SwellSocial )

			@subscriptions = SwellEcom::Subscription.where( user: @user ).order( created_at: :desc )
			@orders = SwellEcom::Order.where( user: @user ).order( created_at: :desc )
			# @user_events = SwellMedia::UserEvent.where( guest_session_id: SwellMedia::GuestSession.where( user_id: @user.id ).pluck( :id ) ).order( created_at: :asc ).page(params[:page]).per(50)
			@preferred_address = SwellEcom::GeoAddress.find_by( user: @user, preferred: true )

			@addresses = SwellEcom::GeoAddress.where( user: @user ).order('preferred DESC, created_at DESC')
		end


		def index

			sort_by = params[:sort_by] || 'created_at'
			sort_dir = params[:sort_dir] || 'desc'

			@users = SwellMedia.registered_user_class.constantize.order( "#{sort_by} #{sort_dir}" )


			( params[:filters] || [] ).each do |key, value|

				@users = @users.where( key => value ) unless value.blank?

			end

			if params[:q].present?
				@users = @users.where( "name like :q OR first_name like :q OR last_name like :q OR email like :q", q: "%#{params[:q]}%" )
			end

			@users = @users.page( params[:page] )

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

	end

end
