module BazaarAdmin
	class ShippingCarrierServiceAdminController < BazaarAdmin::EcomAdminController

		before_action :get_shipping_carrier_plan, only: [ :update, :edit ]

		def edit
			authorize( @shipping_carrier_service )
		end

		def index
			authorize( Bazaar::ShippingCarrierService )
			@shipping_carrier_services = Bazaar::ShippingCarrierService.all

			if ['name', 'carrier', 'service_code', 'created_at'].include? params[:sort_by]
				@shipping_carrier_services = @shipping_carrier_services.order( params[:sort_by] => ( params[:sort_dir] == 'asc' ? :asc : :desc ) )
			else
				@shipping_carrier_services = @shipping_carrier_services.order( status: :desc, name: :asc )
			end

			@shipping_carrier_services = @shipping_carrier_services.page( params[:page] )
		end

		def update
			authorize( @shipping_carrier_service )

			@shipping_carrier_service.attributes = shipping_carrier_plan_attributes

			if @shipping_carrier_service.save
				set_flash 'Success'
			else
				set_flash @shipping_carrier_service.errors.full_messages, :danger
			end

			redirect_back fallback_location: bazaar.edit_shipping_carrier_service_admin_path( @shipping_carrier_service )

		end

		protected
		def get_shipping_carrier_plan
			@shipping_carrier_service = Bazaar::ShippingCarrierService.find(params[:id])
		end
		def shipping_carrier_plan_attributes
			params.require( :shipping_carrier_service ).permit( :shipping_option_id, :name, :description, :status, :carrier, :service_name, :service_code, :service_description, :service_group, :delivery_category )
		end

	end
end
