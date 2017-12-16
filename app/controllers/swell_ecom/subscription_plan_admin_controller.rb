module SwellEcom
	class SubscriptionPlanAdminController < SwellMedia::AdminController

		before_action :get_plan, except: [ :create, :index ]

		def create
			@plan = SubscriptionPlan.new( plan_params )
			@plan.publish_at ||= Time.zone.now
			@plan.status = 'draft'

			if @plan.save
				set_flash 'Plan Created'
				redirect_to edit_subscription_plan_admin_path( @plan )
			else
				set_flash 'Plan could not be created', :error, @plan
				redirect_to :back
			end
		end

		def destroy
			@plan.archive!
			set_flash 'Plan archived'
			redirect_to subscription_plan_admin_index_path
		end


		def index
			sort_by = params[:sort_by] || 'created_at'
			sort_dir = params[:sort_dir] || 'desc'

			@plans = SubscriptionPlan.order( "#{sort_by} #{sort_dir}" )

			if params[:status].present? && params[:status] != 'all'
				@plans = eval "@plans.#{params[:status]}"
			end

			@plans = @plans.page( params[:page] )
		end

		def update

			params[:subscription_plan][:price] = params[:subscription_plan][:price].to_f * 100 
			params[:subscription_plan][:trial_price] = params[:subscription_plan][:trial_price].to_f * 100 
			params[:subscription_plan][:shipping_price] = params[:subscription_plan][:shipping_price].to_f * 100


			@plan.attributes = plan_params
			@plan.save
			redirect_to :back
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