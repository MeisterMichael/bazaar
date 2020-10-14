module Bazaar
	class OrderItemAdminController < Bazaar::EcomAdminController
		before_action :get_order
		before_action :init_order_service


		def create

			@order_item = Bazaar::OrderItem.new( order_item_params )
			authorize( @order_item.order )
			@order_item.title = @order_item.item.title					if @order_item.title.blank?
			@order_item.price = @order_item.item.purchase_price	if order_item_params[:price].blank?
			@order_item.quantity	= 1														if order_item_params[:quanity].blank?

			if @order_item.prod?
				@order_item.subtotal	= @order_item.price * @order_item.quantity
			end

			if @order_item.save
				@order_service.calculate( @order_item.order )

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
						set_flash @order_item.errors.full_messages, :danger
						redirect_back fallback_location: '/admin'
					}
				end
			end

		end

		def destroy

			@order_item = Bazaar::OrderItem.find( params[:id] )
			authorize( @order_item.order )

			if @order_item.destroy
				@order_service.calculate( @order_item.order )

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
						set_flash @order_item.errors.full_messages, :danger
						redirect_back fallback_location: '/admin'
					}
				end

			end

		end

		def update

			@order_item = Bazaar::OrderItem.find( params[:id] )
			authorize( @order_item.order )

			@order_item.attributes = order_item_params
			@order_item.subtotal	= @order_item.price * @order_item.quantity if @order_item.prod?

			if @order_item.save
				@order_service.calculate( @order_item.order )

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
						set_flash @order_item.errors.full_messages, :danger
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

			def order_item_params
				params.require( :order_item ).permit(
					:item_polymorphic_id,
					:item_type,
					:item_id,
					:quantity,
					:price,
					:price_as_money,
					:price_as_money_string,
					:subtotal,
					:subtotal_as_money,
					:subtotal_as_money_string,
					:order_item_type,
					:title,
					:tax_code,
					:order_id,
				)
			end

	end
end
