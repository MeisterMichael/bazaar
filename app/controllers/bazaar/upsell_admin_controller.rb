module Bazaar
	class UpsellAdminController < Bazaar::EcomAdminController

		before_action :get_upsell, except: [:index,:new,:create]

		def create
			authorize( Bazaar::Upsell )

			@upsell = Bazaar::Upsell.new upsell_params

			if @upsell.save
				set_flash "Upsell Created", :success
			else
				set_flash @upsell.errors.full_messages, :danger
			end
			redirect_to upsell_admin_index_path()
		end

		def destroy
			if @upsell.trash!
				set_flash "Upsell deleted", :success
			else
				set_flash @upsell.errors.full_messages, :danger
			end
			redirect_back fallback_location: upsell_admin_index_path()
		end

		def index
			@upsells = Bazaar::Upsell.all

			if params[:status].present?
				@upsells = @upsells.where( status: params[:status] ) 
			else
				@upsells = @upsells.where( status: ['active','draft'] )
			end

			@upsells = @upsells.where( upsell_type: params[:upsell_type] ) if params[:upsell_type].present?

			@upsells = @upsells.joins(:offer).merge(Bazaar::Offer.joins(:product))

			@upsells = @upsells.order( Arel.sql("COALESCE(bazaar_products.slug,bazaar_offers.code)") ).page( params[:page] ).per( 10 )

			set_page_meta( title: "Upsell Admin" )
		end

		def edit
			authorize( @upsell )

			set_page_meta( title: "Upsell Admin" )
		end

		def new
			@upsell = Bazaar::Upsell.new

			authorize( @upsell )

			set_page_meta( title: "Upsell Admin" )
		end

		def update
			authorize( @upsell )

			@upsell.attributes = upsell_params

			if @upsell.save
				set_flash "Upsell Updated", :success
			else
				set_flash @upsell.errors.full_messages, :danger
			end

			redirect_back fallback_location: upsell_admin_index_path()

		end

		protected
		def get_upsell
			@upsell = Bazaar::Upsell.find params[:id]
		end

		def upsell_params
			params.require(:upsell).permit( :offer_id, :full_price_offer_id, :upsell_type, :status, :title, :description, :supplemental_disclaimer, :savings, :full_price, :image_attachment, :image_url, :internal_title, :internal_description, :tags_csv )
		end

	end
end
