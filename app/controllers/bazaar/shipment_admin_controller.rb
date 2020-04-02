module Bazaar
	class ShipmentAdminController < Bazaar::EcomAdminController

		before_action :get_services
		before_action :initialize_search_service, only: [:index]

		def create

			if params[:shipment_id]
				old_shipment = Bazaar::Shipment.find(params[:shipment_id])
				@shipment = Bazaar::Shipment.new({
					code: 								nil,
					status:								'draft',
					notes:								old_shipment.notes,
					email:								old_shipment.email,
					length:								old_shipment.length,
					width:								old_shipment.width,
					height:								old_shipment.height,
					shape:								old_shipment.shape,
					weight:								old_shipment.weight,
					cost:									old_shipment.cost,
					destination_address:	old_shipment.destination_address,
					destination_user_address:	old_shipment.destination_user_address,
					source_address:				old_shipment.source_address,
					order:								old_shipment.order,
					warehouse:						old_shipment.warehouse,
					user:									old_shipment.user,
					price:								old_shipment.price,
					processable_at:				old_shipment.processable_at,
					declared_value:				old_shipment.declared_value,
					tax:									old_shipment.tax,
					tax_breakdown:				old_shipment.tax_breakdown,
					currency:							old_shipment.currency,
				} )
				@shipment.attributes = shipment_params if params[:shipment]

				old_shipment.shipment_skus.each do |shipment_sku|
					@shipment.shipment_skus.new(
						sku_id: shipment_sku.sku_id,
						quantity: shipment_sku.quantity,
						shipping_code: shipment_sku.shipping_code
					)
				end
			else
				@shipment = Bazaar::Shipment.new shipment_params
			end

			@shipment.destination_address ||= @shipment.destination_user_address.try(:geo_address)

			authorize( @shipment )

			if @shipment.save
				set_flash "Shipment created"
				if params[:success_redirect_path]
					redirect_to params[:success_redirect_path]
				else
					redirect_to edit_shipment_admin_path( @shipment, calculate_shipping: params[:calculate_shipping] )
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
			@shipping_service = Bazaar.shipping_service_class.constantize.new( Bazaar.shipping_service_config )

			@shipment = Bazaar::Shipment.find( params[:id] )
			authorize( @shipment )

			@shipping_service.calculate_shipment( @shipment ) if params[:calculate_shipping] && @shipment.destination_address.present?

			set_page_meta( title: "Shipment #{@shipment.created_at}" )

			if @shipment.draft?
				render( 'bazaar/shipment_admin/edit_draft' )
			else
				render( 'bazaar/shipment_admin/edit' )
			end
		end


		def index
			authorize( Bazaar::Shipment )
			@sort_by = params[:sort_by] || 'created_at'
			@sort_dir = params[:sort_dir] || 'desc'

			filters = ( params[:filters] || {} ).select{ |attribute,value| not( value.nil? ) }
			filters[ params[:status] ] = true if params[:status].present? && params[:status] != 'all'
			@shipments = @search_service.shipment_search( params[:q], filters, page: params[:page], order: { @sort_by => @sort_dir } )

			set_page_meta( title: "Shipments" )
			render( 'bazaar/shipment_admin/index' )
		end

		def new
			@shipment = Bazaar::Shipment.new shipment_params
			@shipment.warehouse_id ||= Bazaar.shipping_service_class.constantize.find_warehouse_by_shipment( @shipment ) if Bazaar.shipping_service_class.constantize.respond_to? :find_warehouse_by_shipment

			get_destination_addresses

			@shipment.destination_user_address ||= @shipment.user.preferred_shipping_user_address if @shipment.user
			@shipment.destination_user_address ||= @destination_user_addresses.first

			@shipment.destination_address ||= @shipment.destination_user_address.try(:geo_address)

			authorize( @shipment )

			render( 'bazaar/shipment_admin/new' )
		end

		def update
			@shipment = Bazaar::Shipment.find( params[:id] )
			authorize( @shipment )

			@shipment.attributes = shipment_params
			@shipment.shipment_skus.each do |shipping_sku|
				shipping_sku.shipping_code ||= shipping_sku.warehouse_sku.try(:code)
			end

			if @shipment.shipping_carrier_service_id_changed? && @shipment.shipping_carrier_service

				rates = @shipping_service.calculate_shipment( @shipment, shipping_carrier_service_id: @shipment.shipping_carrier_service.id )
				rate = rates[:rates].find{|rate| rate[:selected] }

				@shipment.cost										= rate[:cost]
				@shipment.carrier									= rate[:carrier]
				@shipment.carrier_service_level		= rate[:carrier_service_level]
				@shipment.requested_service_level	= rate[:requested_service_level]

			elsif @shipment.shipping_carrier_service_id_changed? && @shipment.shipping_carrier_service.nil?

				@shipment.clear_shipping_carrier_service

			end



			if @shipment.save
				set_flash 'Shipment Updated'
				redirect_to edit_shipment_admin_path( id: @shipment.id, calculate_shipping: params[:calculate_shipping] )
			else
				set_flash 'Shipment could not be Updated', :error, @shipment
				redirect_back fallback_location: '/admin'
			end

		end

		protected
		def get_services
			@shipping_service = Bazaar.shipping_service_class.constantize.new( Bazaar.shipping_service_config )
		end

		def get_destination_addresses
			@destination_user_addresses = UserAddress.none
			@destination_user_addresses = @shipment.user.user_addresses.canonical if @shipment.user
		end

		def shipment_params
			shipment_attributes = {} unless params[:shipment].present?
			shipment_attributes ||= params.require( :shipment ).permit(
				:user_id,
				:warehouse_id,
				:notes,
				:status,
				:email,
				:fulfillment_id,
				:fulfilled_by,
				:estimated_delivered_at,
				:canceled_at,
				:packed_at,
				:shipped_at,
				:delivered_at,
				:returned_at,
				:processable_at,
				:order_id,
				:destination_user_address_id,
				:cost_as_money,
				:cost,
				:price_as_money,
				:price,
				:tax_as_money,
				:tax,
				:declared_value_as_money,
				:declared_value,
				:shipping_carrier_service_id,
				:carrier,
				:carrier_service_level,
				:requested_service_level,
				{
					shipment_skus_attributes: [:sku_id,:quantity],
					destination_user_address_attributes: [ :user_id, :phone, :zip, :geo_country_id, :geo_state_id, :state, :city, :street2, :street, :last_name, :first_name ],
				}
			)

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

			if shipment_attributes[:destination_user_address_id].present? && shipment_attributes[:destination_user_address_id] != 'on'
				shipment_attributes.delete(:destination_user_address_attributes)
			else
				shipment_attributes.delete(:destination_user_address_id)
			end

			shipment_attributes
		end

		def initialize_search_service
			@search_service = EcomSearchService.new
		end

	end
end
