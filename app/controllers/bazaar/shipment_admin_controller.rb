module Bazaar
	class ShipmentAdminController < Bazaar::EcomAdminController

		def index
			authorize( Bazaar::Shipment )
			@sort_by = params[:sort_by] || 'created_at'
			@sort_dir = params[:sort_dir] || 'desc'

			@shipments = Bazaar::Shipment.all
			@shipments = @shipments.order( @sort_by => @sort_dir )
			@shipments = @shipments.page( params[:page] ).per( params[:per] || 20 )

			set_page_meta( title: "Shipments" )
		end

	end
end
