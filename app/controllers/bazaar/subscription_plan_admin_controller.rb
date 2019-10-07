module Bazaar
	class SubscriptionPlanAdminController < Bazaar::EcomAdminController


		before_action :get_plan, except: [ :create, :index ]
		before_action :init_search_service, only: [:index]

		def create
			authorize( Bazaar::SubscriptionPlan )

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
			authorize( @plan )
			@plan.archive!
			set_flash 'Plan archived'
			redirect_to subscription_plan_admin_index_path
		end

		def edit
			authorize( @plan )

			set_page_meta( title: "#{@plan.title} | Subscription Plan" )
		end


		def index
			authorize( Bazaar::SubscriptionPlan )

			sort_by = params[:sort_by] || 'created_at'
			sort_dir = params[:sort_dir] || 'desc'

			filters = ( params[:filters] || {} ).select{ |attribute,value| not( value.nil? ) }
			filters[:status] = params[:status] if params[:status].present?
			@plans = @search_service.subscription_plan_search( params[:q], filters, page: params[:page], order: { sort_by => sort_dir } )

			set_page_meta( title: "Subscription Plans" )
		end

		def update
			authorize( @plan )

			@plan.attributes = plan_params
			if @plan.save
				set_flash "Plan Updated", :success
			else
				set_flash @plan.errors.full_messages, :danger
			end
			redirect_back fallback_location: '/admin'
		end

		private

			def init_search_service
				@search_service = EcomSearchService.new
			end

			def plan_params
				params.require( :subscription_plan ).permit( :title, :billing_interval_unit, :billing_interval_value, :billing_statement_descriptor, :price_as_money, :trial_price_as_money, :trial_interval_unit, :trial_interval_value, :trial_max_intervals, :subscription_plan_type, :seq, :avatar, :avatar_attachment, :status, :availability, :package_shape, :package_weight, :package_length, :package_width, :package_height, :description, :content, :cart_description, :publish_at, :shipping_price_as_money, :trial_sku, :product_sku, :trial_offer_sku_id, :renewal_offer_sku_id, :item_id, :item_type )
			end

			def get_plan
				@plan = SubscriptionPlan.friendly.find( params[:id] )
			end

	end
end
