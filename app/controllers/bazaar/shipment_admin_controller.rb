module Bazaar
	class ShipmentAdminController < Bazaar::EcomAdminController

		def edit
			@shipment = Bazaar::Shipment.find( params[:id] )
			authorize( @shipment )

			set_page_meta( title: "Shipment #{@shipment.created_at}" )
		end

		def index
			authorize( Bazaar::Shipment )
			@sort_by = params[:sort_by] || 'created_at'
			@sort_dir = params[:sort_dir] || 'desc'

			@shipments = Bazaar::Shipment.all
			@shipments = @shipments.order( @sort_by => @sort_dir )
			@shipments = @shipments.page( params[:page] ).per( params[:per] || 20 )

			set_page_meta( title: "Shipments" )
		end

		def update
			@shipment = Bazaar::Shipment.find( params[:id] )
			authorize( @shipment )

			@shipment.attributes = shipment_params

			if @shipment.save
				set_flash 'Shipment Updated'
				redirect_to edit_shipment_admin_path( id: @shipment.id )
			else
				set_flash 'Shipment could not be Updated', :error, @shipment
				render :edit
			end

		end

		protected
		def shipment_params
			params.require( :shipment ).permit( :status, :processable_at )
		end

	end
end
