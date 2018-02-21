module SwellEcom
	class SubscriptionPlanAdminController < SwellMedia::AdminController


		before_action :get_plan, except: [ :create, :index ]

		def create
			authorize( SwellEcom::SubscriptionPlan, :admin_create? )

			@plan = SubscriptionPlan.new( plan_params )
			@plan.publish_at ||= Time.zone.now
			@plan.status = 'draft'

			if @plan.save
				set_flash 'Plan Created'
				redirect_to edit_subscription_plan_admin_path( @plan )
			else
				set_flash 'Plan could not be created', :error, @plan
				redirect_back fallback_location: '/admin'
			end
		end

		def destroy
			authorize( @plan, :admin_destroy? )
			@plan.archive!
			set_flash 'Plan archived'
			redirect_to subscription_plan_admin_index_path
		end

		def edit
			authorize( @plan, :admin_edit? )
			@images = SwellMedia::Asset.where( parent_obj: @plan, use: 'gallery' ).active

			set_page_meta( title: "#{@plan.title} | Subscription Plan" )
		end


		def index
			authorize( SwellEcom::SubscriptionPlan, :admin? )

			sort_by = params[:sort_by] || 'created_at'
			sort_dir = params[:sort_dir] || 'desc'

			@plans = SubscriptionPlan.order( "#{sort_by} #{sort_dir}" )

			if params[:status].present? && params[:status] != 'all'
				@plans = eval "@plans.#{params[:status]}"
			end

			@plans = @plans.page( params[:page] )

			set_page_meta( title: "Subscription Plans" )
		end

		def update
			authorize( @plan, :admin_update? )

			params[:subscription_plan][:price] = params[:subscription_plan][:price].to_f * 100
			params[:subscription_plan][:trial_price] = params[:subscription_plan][:trial_price].to_f * 100
			params[:subscription_plan][:shipping_price] = params[:subscription_plan][:shipping_price].to_f * 100


			@plan.attributes = plan_params
			if @plan.save
				set_flash "Plan Updated", :success
			else
				set_flash @plan.errors.full_messages, :danger
			end
			redirect_back fallback_location: '/admin'
		end

		private

			def plan_params
				params.require( :subscription_plan ).permit( :title, :billing_interval_unit, :billing_interval_value, :billing_statement_descriptor, :trial_price, :trial_interval_unit, :trial_interval_value, :trial_max_intervals, :subscription_plan_type, :seq, :avatar, :status, :description, :content, :publish_at, :shipping_price )
			end

			def get_plan
				@plan = SubscriptionPlan.friendly.find( params[:id] )
			end

	end
end
