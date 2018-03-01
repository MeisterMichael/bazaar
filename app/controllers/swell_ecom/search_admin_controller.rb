module SwellEcom
	class SearchAdminController < SwellEcom::EcomAdminController

		def index

			filters = ( params[:filters] || [] ).select{ |filter| not( filter.nil? ) }
			@users = @search_service.user_search( params[:q], filters, page: params[:page], sort_by => sort_dir )
		end

		private

		def init_search_service
			@search_service = EcomSearchService.new
		end
	end
end
