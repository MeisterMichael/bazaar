module Bazaar
	class UpsellOfferAdminController < Bazaar::EcomAdminController

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
			@upsell_offers = Bazaar::UpsellOffer.all

			if params[:status].present?
				@upsell_offers = @upsell_offers.where( status: params[:status] ) 
			else
				@upsell_offers = @upsell_offers.where( status: ['active','draft'] )
			end

			@upsell_offers = @upsell_offers.where( upsell_type: params[:upsell_type] ) if params[:upsell_type].present?

			@upsell_offers = @upsell_offers.joins('LEFT JOIN "bazaar_products" ON "bazaar_products"."id" = "bazaar_upsell_offers"."src_product_id"')
			@upsell_offers = @upsell_offers.joins('LEFT JOIN "bazaar_offers" ON "bazaar_offers"."id" = "bazaar_upsell_offers"."src_offer_id"')

			@upsell_offers = @upsell_offers.order( Arel.sql("COALESCE(bazaar_products.slug,bazaar_offers.code)") ).page( params[:page] ).per( 10 )

			set_page_meta( title: "Upsell Offer Admin" )
		end

		def edit
			authorize( @upsell_offer )

			set_page_meta( title: "Upsell Offer Admin" )
		end

		def update
			authorize( @upsell_offer )

			@upsell_offer.attributes = upsell_offer_params

			if @upsell_offer.save
				set_flash "Upsell Offer Updated", :success
				if @upsell_offer.src_offer.present?
					redirect_to edit_offer_admin_path( @upsell_offer.src_offer )
				elsif @upsell_offer.src_product.present?
					redirect_to edit_product_admin_path( @upsell_offer.src_product )
				end
			else
				set_flash @upsell_offer.errors.full_messages, :danger

				if @upsell_offer.src_offer.present?
					redirect_back fallback_location: edit_offer_admin_path( @upsell_offer.src_offer )
				elsif @upsell_offer.src_product.present?
					redirect_back fallback_location: edit_product_admin_path( @upsell_offer.src_product )
				else
					redirect_back fallback_location: admin_index_path()
				end
			end


		end

		protected
		def get_upsell_offer
			@upsell_offer = Bazaar::UpsellOffer.find params[:id]
		end

		def upsell_offer_params
			params.require(:upsell_offer).permit( :src_offer_id, :src_product_id, :offer_id, :full_price_offer_id, :upsell_type, :status, :title, :description, :supplemental_disclaimer, :savings, :full_price, :image_url )
		end

	end
end
