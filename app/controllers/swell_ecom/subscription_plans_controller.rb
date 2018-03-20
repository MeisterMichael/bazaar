module SwellEcom
	class SubscriptionPlansController < ApplicationController
		layout 'swell_ecom/application'

		before_action :get_plan, except: [ :index ]

		def index
			@plans = SubscriptionPlan.active
		end

		def show


			@images = SwellMedia::Asset.where( parent_obj: @plan, use: 'gallery' ).active

			set_page_meta( @plan.page_meta )

			add_page_event_data(
				ecommerce: {
					detail: {
						actionField: {},
						products: [ @plan.page_event_data ]
					}
				}
			);

			if defined?( SwellAnalytics )
				log_analytics_event(
					'view_details',
					event_category: 'swell_ecom',
					country: client_ip_country,
					ip: client_ip,
					user_id: current_user.try(:id),
					referrer_url: request.referrer,
					page_url: request.original_url,
					subject_id: @plan.id,
					subject_type: @plan.class.base_class.name,
					value: @plan.price,
				)
			end

		end

		private
			def get_plan
				@plan = SubscriptionPlan.friendly.find( params[:id] )
			end

	end
end
