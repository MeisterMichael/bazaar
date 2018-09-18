module SwellEcom
	class WholesaleItemAdminController < SwellEcom::EcomAdminController

		before_action :get_wholesale_item, except: [ :index, :create ]

		def create
			authorize( SwellEcom::WholesaleItem )

			@wholesale_item = WholesaleItem.create( wholesale_item_params )

			if @wholesale_item.save

				set_flash 'Item added', :success

			else

				set_flash 'Item could not be created', :error, @wholesale_item

			end

			redirect_back fallback_location: '/admin'

		end

		def destroy
			authorize( @wholesale_item )
			@wholesale_item.destroy

			set_flash 'Item Removed', :success
			redirect_back fallback_location: '/admin'
		end


		def update
			authorize( @wholesale_item )
			@wholesale_item.attributes = wholesale_item_params
			@wholesale_item.save
			set_flash 'Item Updated', :success
			redirect_back fallback_location: '/admin'
		end

		private
			def wholesale_item_params
				params.require( :wholesale_item ).permit( :wholesale_profile_id, :item_type, :item_id, :item_polymorphic_id, :price, :min_quantity, :price_as_money )
			end

			def get_wholesale_item
				@wholesale_item = WholesaleItem.find_by( id: params[:id] )
			end

	end
end
