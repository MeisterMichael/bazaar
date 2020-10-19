module BazaarAdmin
	class WarehouseAdminController < BazaarAdmin::EcomAdminController

		before_action :get_warehouse, except: [:index,:new,:create]

		def create
			authorize( Bazaar::Warehouse )

			@warehouse = Bazaar::Warehouse.new( warehouse_params )

			if @warehouse.save
				set_flash 'Warehouse Created'
				redirect_to edit_warehouse_admin_path( @warehouse )
			else
				set_flash 'Warehouse could not be created', :error, @warehouse
				redirect_back fallback_location: warehouse_admin_index_path()
			end
		end

		def destroy
			if @warehouse.trash!
				set_flash "Warehouse deleted", :success
				redirect_to warehouse_admin_index_path()
			else
				set_flash @warehouse.errors.full_messages, :danger
				redirect_back fallback_location: warehouse_admin_index_path()
			end
		end

		def index
			@warehouses = Bazaar::Warehouse.all.order( name: :asc ).page( params[:page] ).per( 10 )

			set_page_meta( title: "Warehouse Admin" )
		end

		def edit
			authorize( @warehouse )

			@shipments = @warehouse.shipments.order( created_at: :desc ).page(params[:page]).per(10)
			@warehouse_countries = @warehouse.warehouse_countries.includes(:geo_country).order('geo_countries.name ASC')
			@warehouse_states = @warehouse.warehouse_states.includes(:geo_state).merge( GeoState.includes(:geo_country) ).order('geo_countries.name ASC, geo_states.name ASC')
			@warehouse_skus = @warehouse.warehouse_skus.includes(:sku).order('bazaar_skus.code ASC')

			set_page_meta( title: "#{@warehouse.name} | Warehouse Admin" )
		end

		def update
			authorize( @warehouse )

			@warehouse.attributes = warehouse_params

			log_event( { name:'warehouse_update', category: 'admin', on: @warehouse, content: "changed #{@warehouse.name}: #{@warehouse.changes.collect{|attribute,changes| "#{attribute} changed from '#{changes.first}' to '#{changes.last}'" }.join(', ')}." } ) if @warehouse.changes.present?

			if @warehouse.save
				set_flash "Warehouse Updated", :success
			else
				set_flash @warehouse.errors.full_messages, :danger
			end
			redirect_back fallback_location: warehouse_admin_index_path()
		end

		protected
		def get_warehouse
			@warehouse = Bazaar::Warehouse.friendly.find params[:id]
		end

		def warehouse_params
			params.require(:warehouse).permit( :name, :geo_address_id, :status, :country_restriction_type, :state_restriction_type )
		end

	end
end
