module Bazaar
	class ShippingOptionAdminController < Bazaar::EcomAdminController

		before_action :get_shipping_option, only: [ :update, :edit ]

		def create
			authorize( Bazaar::ShippingOption )

			@shipping_option = Bazaar::ShippingOption.new
			@shipping_option.attributes = shipping_carrier_plan_attributes

			if @shipping_option.save
				set_flash 'Success'
			else
				set_flash @shipping_option.errors.full_messages, :danger
			end

			redirect_back fallback_location: bazaar.edit_shipping_option_admin_path( @shipping_option )

		end

		def edit
			authorize( @shipping_option )
		end

		def index
			authorize( Bazaar::ShippingOption )
			@shipping_options = Bazaar::ShippingOption.all

			if ['name', 'created_at'].include? params[:sort_by]
				@shipping_options = @shipping_options.order( params[:sort_by] => ( params[:sort_dir] == 'asc' ? :asc : :desc ) )
			else
				@shipping_options = @shipping_options.order( status: :desc, name: :asc )
			end

			@shipping_options = @shipping_options.page( params[:page] )
		end

		def update
			authorize( @shipping_option )

			@shipping_option.attributes = shipping_carrier_plan_attributes

			if @shipping_option.save
				set_flash 'Success'
			else
				set_flash @shipping_option.errors.full_messages, :danger
			end

			redirect_back fallback_location: bazaar.edit_shipping_option_admin_path( @shipping_option )

		end

		protected
		def get_shipping_option
			@shipping_option = Bazaar::ShippingOption.find(params[:id])
		end
		def shipping_carrier_plan_attributes
			params.require( :shipping_option ).permit( :name, :description, :status, :short_description )
		end

	end
end
