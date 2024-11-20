module Bazaar
	class ShipmentAdminController < Bazaar::EcomAdminController

		before_action :get_services
		before_action :initialize_search_service, only: [:index]

		def batch_create
			application_shipping_service = ApplicationShippingService.new( Bazaar.shipping_service_config )

			warehouse = nil # Bazaar::Warehouse.find_by( fulfillment_service_code: 'rsl' )

			batch_id = params[:batch_id] || "Batch #{Time.now.to_i}"
			batch_date = Time.now.to_s

			csv_file = params[:file]
			csv = CSV.parse( File.read( csv_file.path ), headers: true )

			shipment_rows = []
			csv.each_with_index do |shipment_row, index|
				shipment_row = shipment_row.to_h
				shipment_row.each do |key,value|
					shipment_row[key] = value.try(:strip)
				end

				shipment_rows << shipment_row
			end

			required_columns = [ 'EMAIL', 'FULL NAME', 'STREET 1', 'STREET 2', 'CITY', 'ZIPCODE', 'STATE', 'COUNTRY', "ITEM 1 QUANTITY", "ITEM 1 SKU" ]
			if shipment_rows.count == 0
				set_flash "CSV is Empty", :danger
				redirect_back fallback_location: shipment_admin_index_path()
				return false
			elsif (missing_columns = required_columns - shipment_rows.first.keys).count > 0
				set_flash "CSV is missing columns: \"#{missing_columns.join('","')}\"", :danger
				redirect_back fallback_location: shipment_admin_index_path()
				return false
			end

			shipments = []
			shipment_rows.each_with_index do |shipment_row, index|
				shipment_row = shipment_row.to_h

				shipment_skus = []
				sku_i = 1
				while( shipment_row["ITEM #{sku_i} SKU"].present? )
					code = shipment_row["ITEM #{sku_i} SKU"]
					shipment_skus << { sku: Bazaar::Sku.find_by( code: code ), quantity: (shipment_row["ITEM #{sku_i} QUANTITY"] || 1).to_i }
					sku_i += 1
				end

				source_identifier	= shipment_row['EXTERNAL REFERENCE']
				source_system			= shipment_row['EXTERNAL SOURCE']

				state_field = shipment_row['REGION'] if shipment_row['REGION'].present?
				state_field ||= shipment_row['STATE'] if shipment_row['STATE'].present?

				geo_country = GeoCountry.find_by( abbrev: shipment_row['COUNTRY'] )
				if geo_country && ['US','CA'].include?( geo_country.abbrev )
					geo_state = GeoState.where( abbrev: state_field, geo_country: geo_country ).first
					geo_state ||= GeoState.where( geo_country: geo_country ).where( 'LOWER(name) = ?', state_field.downcase ).first
				end
				state = state_field unless geo_state.present?

				split_full_name = shipment_row['FULL NAME'].split(' ',2)

				shipment_email = shipment_row['EMAIL']

				shipment_user = User.create_with( first_name: split_full_name.first, last_name: split_full_name.second ).find_or_create_by( email: shipment_email.downcase )

				destination_user_address = UserAddress.canonical_find_or_create_with_cannonical_geo_address(
					first_name: split_full_name.first,
					last_name: split_full_name.second,
					street: shipment_row['STREET 1'],
					street2: shipment_row['STREET 2'],
					city: shipment_row['CITY'],
					geo_state: geo_state,
					state: state,
					zip: shipment_row['ZIPCODE'],
					geo_country: geo_country,
					# phone: shipment_row['Phone'],
					user: shipment_user,
				)

				puts "destination_user_address.errors.full_messages #{destination_user_address.errors.full_messages}"
				puts "destination_user_address.errors.full_messages #{destination_user_address.to_html}"

				if Bazaar::Shipment.where( "(properties::hstore -> 'BATCH_ID') = ?", batch_id ).where( "(properties::hstore -> 'IMPORT_INDEX') = ?", index.to_s ).present?
					puts "  - already exists"
					next
				end

				shipment = Bazaar::Shipment.new({
					email: shipment_email,
					user: shipment_user,
					dyanically_configured:		true,
					source_identifier: 				source_identifier,
					source_system: 						source_system,
					# code: 										nil,
					status:										'draft',
					properties:								{
						"BATCH_ID"								=> batch_id,
						"BATCH_DATE"							=> batch_date,
						"IMPORT_ROW"							=> shipment_row.to_json,
						"IMPORT_INDEX"						=> index.to_s,
					},
					# notes:										nil,
					# email:										nil,
					# length:										nil,
					# width:										nil,
					# height:										nil,
					# shape:										nil,
					# weight:										nil,
					# cost:											nil,
					destination_user_address:		destination_user_address,
					destination_address:				destination_user_address.geo_address,
					# source_address:						nil,
					# order:										nil,
					# shipping_carrier_service:	Bazaar::ShippingCarrierService.find_by( service_name: "Standard", service_code: 'DHL', carrier: 'DHL' ),
					warehouse:								warehouse,
					# fulfilled_by:							nil,
					# user:											nil,
					# price:										nil,
					processable_at:						Time.now,
					# declared_value:						nil,
					# tax:											nil,
					# tax_breakdown:						nil,
					# currency:									nil,
				} )

				shipment_skus.each do |shipment_sku|
					shipment.shipment_skus.new(shipment_sku)
				end

				application_shipping_service.calculate_shipment( shipment )

				shipment.save!

				shipments << shipment
			end

			successes = shipments.select(&:persisted?).count
			failures = shipment_rows.count - successes
			if successes > 0
				set_flash "#{successes} #{'Shipment'.pluralize( successes )} Created"
			end

			if failures > 0
				set_flash "#{failures} #{'Shipment'.pluralize( failures )} Failed", :error
			end

			redirect_to shipment_admin_index_path( 'filters[batch_id]' => batch_id )

		end

		def batch_template
			csv_array = [
				['EMAIL',					'FULL NAME',	'STREET 1',	'STREET 2',	'CITY',				'ZIPCODE',	'STATE',	'COUNTRY',	"ITEM 1 QUANTITY",	"ITEM 1 SKU",					"ITEM 2 QUANTITY",	"ITEM 2 SKU"],
				['mike@nhc.com',	'Mike Ferg',	'123 A St',	'',					'San Diego',	'92126',		'CA',			'US',				'2',								"Eternus.160capsule",	"1",								"	Qualia.Focus.100capsules"],
			]

			respond_to do |format|
				format.csv { send_data csv_array.collect(&:to_csv).join(""), filename: "batch_template.csv" }
			end

		end

		def batch_update
			@shipments = Bazaar::Shipment.all

			if params[:batch_id].present?
				@shipments = @shipments.where( "(properties::hstore -> 'BATCH_ID') = ?", params[:batch_id] )
			else
				@shipments = @shipments.where( id: params[:ids] )
			end

			authorize( @shipments )

			attributes = shipment_params.merge( updated_at: Time.now )
			puts "attributes #{attributes.to_json}"
			@successes	= @shipments.update( attributes )

			set_flash "#{@shipments.count} #{'Shipment'.pluralize( @shipments.count )} Updated"

			redirect_back fallback_location: shipment_admin_index_path()
		end

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

			@shipping_service.calculate_shipment( @shipment ) if params[:calculate_shipping] && @shipment.destination_user_address.present?

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

			@source_systems = Bazaar::Shipment.order(source_system: :asc).pluck('distinct source_system')

			filters = ( params[:filters] || {} ).select{ |attribute,value| not( value.nil? ) }
			filters[ params[:status] ] = true if params[:status].present? && params[:status] != 'all'
			filters[:source_system] = params[:source_system] if params[:source_system].present?
			filters[:source_system] = nil if params[:source_system] == '-'

			if ( @batch_id = filters[:batch_id] ).present?
				@shipments = Bazaar::Shipment.all.where( "(properties::hstore -> 'BATCH_ID') = ?", @batch_id ).order( @sort_by => @sort_dir )
			else
				@shipments = @search_service.shipment_search( params[:q], filters, page: params[:page], order: { @sort_by => @sort_dir }, mode: params[:search_mode] )
			end

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
				:source_system,
				:source_identifier,
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
			@search_service = Bazaar.search_service_class.constantize.new( Bazaar.search_service_config )
		end

	end
end
