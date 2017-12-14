module SwellEcom
	class SubscriptionAdminController < SwellMedia::AdminController

		before_filter :get_subscription, except: [ :index ]

		def edit
			@orders = Order.where( parent: @subscription )
		end

		def index
			sort_by = params[:sort_by] || 'created_at'
			sort_dir = params[:sort_dir] || 'desc'

			@subscriptions = Subscription.order( "#{sort_by} #{sort_dir}" )

			if params[:status].present? && params[:status] != 'all'
				@subscriptions = eval "@subscriptions.#{params[:status]}"
			end

			if params[:q].present?
				@subscriptions = @subscriptions.joins(:user).where( "users.email like :q", q: "'%#{params[:q].downcase}%'" )
			end

			@subscriptions = @subscriptions.page( params[:page] )
		end


		def update
			@subscription = Subscription.where( id: params[:id] ).includes( :user ).first
			@subscription.attributes = subscription_params

			@transaction_service = SwellEcom.transaction_service_class.constantize.new( SwellEcom.transaction_service_config )

			#if @transaction_service.update_subscription( @subscription )

			die

			if @subscription.save
				set_flash "Subscription updated successfully", :success

			else

				set_flash @subscription.errors.full_messages, :danger

			end


			redirect_to :back
		end

		private
			def subscription_params
				params.require( :subscription ).permit( :next_charged_at, :amount, :trial_amount, user_attributes: [ :first_name, :last_name, :email ] )
			end

			def get_subscription
				@subscription = Subscription.find_by( id: params[:id] )
			end

	end
end
