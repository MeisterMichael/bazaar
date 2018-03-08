module SwellEcom
	class ShippingOptionAdminController < SwellEcom::EcomAdminController

		before_action :get_shipping_option, only: [ :update, :edit ]

		def create
			authorize( SwellEcom::ShippingOption, :admin_create? )

			@shipping_option = SwellEcom::ShippingOption.new
			@shipping_option.attributes = shipping_carrier_plan_attributes

			if @shipping_option.save
				set_flash 'Success'
			else
				set_flash @shipping_option.errors.full_messages, :danger
			end

			redirect_back fallback_location: swell_ecom.edit_shipping_option_admin_path( @shipping_option )

		end

		def edit
			authorize( @shipping_option, :admin_edit? )
		end

		def index
			authorize( SwellEcom::ShippingOption, :admin? )
			@shipping_options = SwellEcom::ShippingOption.all

			if ['name', 'created_at'].include? params[:sort_by]
				@shipping_options = @shipping_options.order( params[:sort_by] => ( params[:sort_dir] == 'asc' ? :asc : :desc ) )
			else
				@shipping_options = @shipping_options.order( status: :desc, name: :asc )
			end

			@shipping_options = @shipping_options.page( params[:page] )
		end

		def update
			authorize( @shipping_option, :admin_update? )

			@shipping_option.attributes = shipping_carrier_plan_attributes

			if @shipping_option.save
				set_flash 'Success'
			else
				set_flash @shipping_option.errors.full_messages, :danger
			end

			redirect_back fallback_location: swell_ecom.edit_shipping_option_admin_path( @shipping_option )

		end

		protected
		def get_shipping_option
			@shipping_option = SwellEcom::ShippingOption.find(params[:id])
		end
		def shipping_carrier_plan_attributes
			params.require( :shipping_option ).permit( :name, :description, :status, :short_description )
		end

	end
end
