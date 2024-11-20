module Bazaar
	class SearchAdminController < Bazaar::EcomAdminController

		def index

			filters = ( params[:filters] || [] ).select{ |filter| not( filter.nil? ) }
			@users = @search_service.user_search( params[:q], filters, page: params[:page], sort_by => sort_dir, mode: params[:search_mode] )
		end

		private

		def init_search_service
			@search_service = Bazaar.search_service_class.constantize.new( Bazaar.search_service_config )
		end
	end
end
