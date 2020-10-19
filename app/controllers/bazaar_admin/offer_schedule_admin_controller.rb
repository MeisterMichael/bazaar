module BazaarAdmin
	class OfferScheduleAdminController < BazaarAdmin::EcomAdminController

		before_action :get_offer_schedule, except: [:index,:new,:create]

		def create
			authorize( Bazaar::OfferSchedule )

			@offer_schedule = Bazaar::OfferSchedule.new( offer_schedule_params )

			if params[:replace] == 'duplicate_start_intervals'
				sibling_offer_schedules = @offer_schedule.parent_obj.offer_schedules.active
				sibling_offer_schedules = sibling_offer_schedules.where( start_interval: @offer_schedule.start_interval )
				sibling_offer_schedules.update( status: 'trash' )
			end

			if @offer_schedule.save
				set_flash 'Schedule Added'
				redirect_back fallback_location: sku_admin_index_path()
			else
				set_flash 'Schedule could not be added', :error, @offer_schedule
				redirect_back fallback_location: sku_admin_index_path()
			end
		end

		def destroy
			if @offer_schedule.trash!
				set_flash "Schedule removed", :success
				redirect_back fallback_location: sku_admin_index_path()
			else
				set_flash @offer_schedule.errors.full_messages, :danger
				redirect_back fallback_location: sku_admin_index_path()
			end
		end

		def update
			authorize( @offer_schedule )

			@offer_schedule.attributes = offer_schedule_params
			if @offer_schedule.save
				set_flash "Offer Schedule Updated", :success
			else
				set_flash @offer_schedule.errors.full_messages, :danger
			end
			redirect_back fallback_location: sku_admin_index_path()
		end

		protected
		def get_offer_schedule
			@offer_schedule = Bazaar::OfferSchedule.find params[:id]
		end

		def offer_schedule_params
			params.require(:offer_schedule).permit( :parent_obj_type, :parent_obj_id, :start_interval, :max_intervals, :interval_unit, :interval_value, :status, :trashed_at, :period_type )
		end

	end
end
