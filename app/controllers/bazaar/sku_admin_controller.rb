module Bazaar
	class SkuAdminController < Bazaar::EcomAdminController

		before_action :get_sku, except: [:index,:new,:create]
		before_action :init_search_service, only: :index

		def create
			authorize( Bazaar::Sku )

			@sku = Bazaar::Sku.new( sku_params )

			if @sku.save
				set_flash 'Sku Created'
				redirect_to edit_sku_admin_path( @sku )
			else
				set_flash 'Sku could not be created', :error, @sku
				redirect_back fallback_location: sku_admin_index_path()
			end
		end

		def destroy
			if @sku.trash!
				set_flash "Sku deleted", :success
				redirect_to sku_admin_index_path()
			else
				set_flash @sku.errors.full_messages, :danger
				redirect_back fallback_location: sku_admin_index_path()
			end
		end

		def index
			authorize( Bazaar::Sku )

			sort_by = params[:sort_by] || 'name'
			sort_dir = params[:sort_dir] || 'asc'

			filters = ( params[:filters] || {} ).select{ |attribute,value| not( value.nil? ) }
			params[:status] ||= 'active'
			filters[ params[:status] ] = true if params[:status].present? && params[:status] != 'all'
			@skus = @search_service.sku_search( params[:q], filters, page: params[:page], order: { sort_by => sort_dir } )

			set_page_meta( title: "Sku Admin" )
		end

		def edit
			authorize( @sku )

			@shipments = @sku.shipments.order( created_at: :desc ).page(params[:page]).per(10)
			@sku_countries = @sku.sku_countries.includes(:geo_country).order(Arel.sql('geo_countries.name ASC'))
			@warehouse_skus = @sku.warehouse_skus.includes(:warehouse).order(Arel.sql('bazaar_warehouses.name ASC'))
			@offers = @sku.offer_skus.active.collect{|offer_sku|offer_sku.parent_obj}.uniq.sort_by{|offer| offer.title }


			set_page_meta( title: "#{@sku.code} | Sku Admin" )
		end

		def update
			authorize( @sku )

			@sku.attributes = sku_params
			if @sku.save
				set_flash "Sku Updated", :success
			else
				set_flash @sku.errors.full_messages, :danger
			end
			redirect_back fallback_location: sku_admin_index_path()
		end

		protected
		def get_sku
			@sku = Bazaar::Sku.find params[:id]
		end

		def init_search_service
			@search_service = Bazaar.search_service_class.constantize.new( Bazaar.search_service_config )
		end

		def sku_params
			params.require(:sku).permit( :name, :description, :code, :status, :length, :width, :height, :shape, :weight, :sku_cost_as_money_string, :sku_value_as_money_string, :country_restriction_type, :state_restriction_type, :avatar_attachment, :tags_csv, :gtins_csv, :mpns_csv )
		end

	end
end
