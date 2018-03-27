module SwellEcom
	class OrderItemAdminController < SwellEcom::EcomAdminController
		before_action :get_order


		def create

			order_item = SwellEcom::OrderItem.new( order_item_params )
			authorize( order_item.order, :admin_update? )

			order_item.quantity	||= 1
			order_item.subtotal	= order_item.price * order_item.quantity if order_item.prod?

			if order_item.save
				set_flash "Item Added", :success
			else
				set_flash order_item.errors.full_messages, :danger
			end

			redirect_back fallback_location: '/admin'

		end

		def destroy

			order_item = SwellEcom::OrderItem.find( params[:id] )
			authorize( order_item.order, :admin_update? )

			if order_item.destroy
				set_flash "Item Deleted", :success
			else
				set_flash order_item.errors.full_messages, :danger
			end

			redirect_back fallback_location: '/admin'

		end

		def update

			order_item = SwellEcom::OrderItem.find( params[:id] )
			authorize( order_item.order, :admin_update? )

			order_item.attributes = order_item_params
			order_item.subtotal	= order_item.price * order_item.quantity if order_item.prod?

			if order_item.save
				set_flash "Item Updated", :success
			else
				set_flash order_item.errors.full_messages, :danger
			end

			redirect_back fallback_location: '/admin'

		end

		private

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
					:subtotal,
					:subtotal_as_money,
					:order_item_type,
					:title,
					:tax_code,
					:order_id,
				)
			end

	end
end
