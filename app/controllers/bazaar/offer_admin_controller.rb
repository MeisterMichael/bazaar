module Bazaar
	class OfferAdminController < Bazaar::EcomAdminController

		before_action :get_offer, except: [:index,:new,:create]
		before_action :init_search_service, only: [:index]

		def create
			authorize( Bazaar::Offer )

			@offer = Bazaar::Offer.new( offer_params )
			@offer.cart_title ||= @offer.title

			@offer.offer_prices.new( price_as_money_string: params[:price_as_money], status: 'active', start_interval: 1, max_intervals: nil ) if params[:price_as_money]
			@offer.offer_schedules.new( status: 'active', start_interval: 1, max_intervals: 1, interval_value: 0, interval_unit: 'weeks' )
			@offer.offer_skus.new( sku_id: params[:sku_id], status: 'active', start_interval: 1, max_intervals: nil ) if params[:sku_id]

			if @offer.save
				set_flash 'Offer created'
				redirect_to edit_offer_admin_path( @offer.id )
			else
				set_flash 'Offer could not be created', :error, @offer
				redirect_back fallback_location: offer_admin_index_path()
			end
		end

		def destroy
			authorize( @offer )
			if @offer.trash!
				set_flash "Sku removed", :success
				redirect_back fallback_location: offer_admin_index_path()
			else
				set_flash @offer.errors.full_messages, :danger
				redirect_back fallback_location: offer_admin_index_path()
			end
		end

		def edit
			authorize( @offer )
			set_page_meta( title: "#{@offer.title} - Offers" )

		end

		def index
			authorize( Bazaar::Offer )

			sort_by = params[:sort_by] || 'title'
			sort_dir = params[:sort_dir] || 'asc'

			filters = ( params[:filters] || {} ).select{ |attribute,value| not( value.nil? ) }
			params[:status] ||= 'active'
			filters[ params[:status] ] = true if params[:status].present? && params[:status] != 'all'
			@offers = @search_service.offer_search( params[:q], filters, page: params[:page], order: { sort_by => sort_dir } )

			set_page_meta( title: "Offers" )
		end

		def update
			authorize( @offer )

			@offer.attributes = offer_params
			if @offer.save
				set_flash "Offer Updated", :success
			else
				set_flash @offer.errors.full_messages, :danger
			end
			redirect_back fallback_location: offer_admin_index_path()
		end

		protected
		def get_offer
			@offer = Bazaar::Offer.find params[:id]
		end

		def offer_params
			params.require(:offer).permit( [:status, :availability, :title, :avatar, :avatar_attachment, :code, :tax_code, :description, :cart_title, :cart_description, :product_id, :min_quantity, :tags_csv] + ( BazaarCore.admin_permit_additions[:offer_admin] || [] ) )
		end

		def init_search_service
			@search_service = EcomSearchService.new
		end
	end
end
