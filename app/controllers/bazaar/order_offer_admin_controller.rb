module Bazaar
	class OrderOfferAdminController < Bazaar::EcomAdminController
		before_action :get_order
		before_action :init_order_service


		def create

			@order_offer = Bazaar::OrderOffer.new( order_offer_params )
			authorize( @order_offer.order )
			@order_offer.title = @order_offer.item.title					if @order_offer.title.blank?
			@order_offer.price = @order_offer.item.purchase_price	if order_offer_params[:price].blank?
			@order_offer.quantity	= 1														if order_offer_params[:quanity].blank?
			@order_offer.subtotal	= @order_offer.price * @order_offer.quantity

			if @order_offer.save
				@order_service.calculate( @order_offer.order )

				respond_to do |format|
					format.js {
						render :create
					}
					format.json {
						render :create
					}
					format.html {
						set_flash "Item Added", :success
						redirect_back fallback_location: '/admin'
					}
				end
			else
				respond_to do |format|
					format.js {
						render :create
					}
					format.json {
						render :create
					}
					format.html {
						set_flash @order_offer.errors.full_messages, :danger
						redirect_back fallback_location: '/admin'
					}
				end
			end

		end

		def destroy

			@order_offer = Bazaar::OrderOffer.find( params[:id] )
			authorize( @order_offer.order )

			if @order_offer.destroy
				@order_service.calculate( @order_offer.order )

				respond_to do |format|
					format.js {
						render :destroy
					}
					format.json {
						render :destroy
					}
					format.html {
						set_flash "Item Deleted", :success
						redirect_back fallback_location: '/admin'
					}
				end

			else

				respond_to do |format|
					format.js {
						render :destroy
					}
					format.json {
						render :destroy
					}
					format.html {
						set_flash @order_offer.errors.full_messages, :danger
						redirect_back fallback_location: '/admin'
					}
				end

			end

		end

		def update

			@order_offer = Bazaar::OrderOffer.find( params[:id] )
			authorize( @order_offer.order )

			@order_offer.attributes = order_offer_params
			@order_offer.subtotal	= @order_offer.price * @order_offer.quantity if @order_offer.prod?

			if @order_offer.save
				@order_service.calculate( @order_offer.order )

				respond_to do |format|
					format.js {
						render :update
					}
					format.json {
						render :update
					}
					format.html {
						set_flash "Item Updated", :success
						redirect_back fallback_location: '/admin'
					}
				end
			else

				respond_to do |format|
					format.js {
						render :update
					}
					format.json {
						render :update
					}
					format.html {
						set_flash @order_offer.errors.full_messages, :danger
						redirect_back fallback_location: '/admin'
					}
				end
			end

		end

		private

			def init_order_service
				@order_service = BazaarCore.checkout_order_service_class.constantize.new
			end

			def get_order
				@order = Order.find_by( id: params[:order_id] )
			end

			def order_offer_params
				params.require( :order_offer ).permit(
					:offer_id,
					:quantity,
					:price,
					:price_as_money,
					:price_as_money_string,
					:subtotal,
					:subtotal_as_money,
					:subtotal_as_money_string,
					:title,
					:tax_code,
					:order_id,
				)
			end

	end
end
