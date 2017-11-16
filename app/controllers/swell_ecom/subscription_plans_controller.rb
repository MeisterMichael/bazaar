module SwellEcom
	class SubscriptionPlansController < ApplicationController

		before_filter :get_plan, except: [ :index ]

		def show
			
		end

		private 
			def get_plan
				@plan = SubscriptionPlan.friendly.find( params[:id] )
			end

	end
end