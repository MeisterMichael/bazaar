module SwellEcom
	class SubscriptionPlanAdminController < SwellMedia::AdminController

		before_filter :get_plan, except: [ :create, :index ]

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
			set_flash 'Product archived'
			redirect_to product_admin_index_path
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
			
		end

		private

			def plan_params
				params.require( :subscription_plan ).permit( :title )
			end

			def get_plan
				@plan = SubscriptionPlan.friendly.find( params[:id] )
			end

	end
end