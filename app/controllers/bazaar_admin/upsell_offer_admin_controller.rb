module BazaarAdmin
	class UpsellOfferAdminController < BazaarAdmin::EcomAdminController

		before_action :get_upsell_offer, except: [:index,:new,:create]

		def create
			authorize( Bazaar::UpsellOffer )

			@upsell_offer = Bazaar::UpsellOffer.new upsell_offer_params

			if @upsell_offer.save
				set_flash "Upsell Offer Created", :success
			else
				set_flash @upsell_offer.errors.full_messages, :danger
			end
			redirect_back fallback_location: upsell_offer_admin_index_path()
		end

		def destroy
			if @upsell_offer.trash!
				set_flash "Upsell Offer deleted", :success
			else
				set_flash @upsell_offer.errors.full_messages, :danger
			end
			redirect_back fallback_location: upsell_offer_admin_index_path()
		end

		def index
			@upsell_offers = Bazaar::UpsellOffer.where( status: ['active','draft'] ).order( name: :asc ).page( params[:page] ).per( 10 )

			set_page_meta( title: "Upsell Offer Admin" )
		end

		def edit
			authorize( @upsell_offer )

			set_page_meta( title: "#{@upsell_offer.name} | Upsell Offer Admin" )
		end

		def update
			authorize( @upsell_offer )

			@upsell_offer.attributes = upsell_offer_params

			if @upsell_offer.save
				set_flash "Upsell Offer Updated", :success
			else
				set_flash @upsell_offer.errors.full_messages, :danger
			end
			redirect_back fallback_location: upsell_offer_admin_index_path()
		end

		protected
		def get_upsell_offer
			@upsell_offer = Bazaar::UpsellOffer.find params[:id]
		end

		def upsell_offer_params
			params.require(:upsell_offer).permit( :src_offer_id, :src_product_id, :offer_id, :full_price_offer_id, :upsell_type, :status )
		end

	end
end
