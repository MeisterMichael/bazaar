module Bazaar
	class ShipmentAdminController < Bazaar::EcomAdminController

		def create
			@shipment = Bazaar::Shipment.new shipment_params
			authorize( @shipment )


			if @shipment.save
				set_flash "Shipment created"
				if params[:success_redirect_path]
					redirect_to params[:success_redirect_path]
				else
					redirect_back fallback_location: '/admin'
				end
			else
				set_flash "Unable to create shipment", :danger, @shipment
				if params[:failure_redirect_path]
					redirect_to params[:failure_redirect_path]
				else
					redirect_back fallback_location: '/admin'
				end
			end
		end

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

		def new
			@shipment = Bazaar::Shipment.new shipment_params
			authorize( @shipment )


			@shipping_service = Bazaar.shipping_service_class.constantize.new( Bazaar.shipping_service_config )
			@shipping_service.calculate_shipment( @shipment )

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
			shipment_attributes = params.require( :shipment ).permit( :user_id, :warehouse_id, :notes, :status, :email, :estimated_delivered_at, :canceled_at, :packed_at, :shipped_at, :delivered_at, :returned_at, :processable_at, :order_id, :destination_address_id, :cost_as_money, :cost, :price_as_money, :price, :tax_as_money, :tax, :declared_value_as_money, :declared_value, { shipment_skus_attributes: [:sku_id,:quantity] } )
			if params[:shipping_rate].present?
				shipping_rate = JSON.parse( params[:shipping_rate], symbolize_names: true )
				shipment_attributes = shipment_attributes.merge(
					price: shipping_rate[:price],
					cost: shipping_rate[:cost],
					shipping_carrier_service_id: shipping_rate[:id],
					carrier_service_level: shipping_rate[:carrier_service][:service_name],
					requested_service_level: shipping_rate[:label],
					carrier: shipping_rate[:carrier_service][:carrier],
				)
			end

			shipment_attributes
		end

	end
end
