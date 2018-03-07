module SwellEcom
	class ShippingCarrierServiceAdminController < SwellEcom::EcomAdminController

		before_action :get_shipping_carrier_plan, only: [ :update, :edit ]

		def edit
			authorize( @shipping_carrier_service, :admin_edit? )
		end

		def index
			authorize( SwellEcom::ShippingCarrierService, :admin? )
			@shipping_carrier_services = SwellEcom::ShippingCarrierService.all.page( params[:page] )
		end

		def update
			authorize( @shipping_carrier_service, :admin_update? )

			@shipping_carrier_service.attributes = shipping_carrier_plan_attributes

			if @shipping_carrier_service.save
				set_flash 'Success'
			else
				set_flash @shipping_carrier_service.errors.full_messages, :danger
			end

			redirect_back fallback_location: swell_ecom.edit_shipping_carrier_service_admin_path( @shipping_carrier_service )

		end

		protected
		def get_shipping_carrier_plan
			@shipping_carrier_service = SwellEcom::ShippingCarrierService.find(params[:id])
		end
		def shipping_carrier_plan_attributes
			params.require( :shipping_carrier_service ).permit( :shipping_option_id, :name, :description, :status )
		end

	end
end
