module Bazaar
	class WarehouseAdminController < Bazaar::EcomAdminController

		before_action :get_warehouse, except: [:index,:new,:create]

		def create
			authorize( Bazaar::Warehouse )

			@warehouse = Bazaar::Warehouse.new( warehouse_params )

			if @warehouse.save
				set_flash 'Warehouse Created'
				redirect_to edit_warehouse_admin_path( @warehouse )
			else
				set_flash 'Warehouse could not be created', :error, @warehouse
				redirect_back fallback_location: '/admin'
			end
		end

		def index
			@warehouses = Bazaar::Warehouse.all.order( name: :asc ).page( params[:page] ).per( 10 )

			set_page_meta( title: "Warehouse Admin" )
		end

		def edit
			authorize( @warehouse )

			@shipments = @warehouse.shipments.page(params[:page]).per(10)
			@warehouse_countries = @warehouse.warehouse_countries.includes(:geo_country).order('geo_countries.name ASC')
			@warehouse_skus = @warehouse.warehouse_skus.includes(:sku).order('bazaar_skus.code ASC')

			set_page_meta( title: "#{@warehouse.name} | Warehouse Admin" )
		end

		def update
			authorize( @warehouse )

			@warehouse.attributes = warehouse_params
			if @warehouse.save
				set_flash "Warehouse Updated", :success
			else
				set_flash @warehouse.errors.full_messages, :danger
			end
			redirect_back fallback_location: '/admin'
		end

		protected
		def get_warehouse
			@warehouse = Bazaar::Warehouse.find params[:id]
		end

		def warehouse_params
			params.require(:warehouse).permit( :name, :geo_address_id, :status, :restriction_type )
		end

	end
end
