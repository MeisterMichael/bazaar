module SwellEcom
	class SubscriptionPlansController < ApplicationController
		layout 'swell_ecom/application'

		before_action :get_plan, except: [ :index ]

		def index
			@plans = SubscriptionPlan.active

			log_event
		end

		def show


			set_page_meta( @plan.page_meta )

			add_page_event_data(
				ecommerce: {
					detail: {
						actionField: {},
						products: [ @plan.page_event_data ]
					}
				}
			);

			log_event( on: @plan )
		end

		private
			def get_plan
				@plan = SubscriptionPlan.friendly.find( params[:id] )
			end

	end
end
