module Bazaar
	class CollectionItemAdminController < Bazaar::EcomAdminController
		before_action :get_model, except: [ :create, :index ]

		def create
			authorize( Bazaar::CollectionItem )

			@collection_item = CollectionItem.new( model_params )

			if @collection_item.save
				set_flash 'Collection Item Created'
				redirect_to edit_collection_admin_path( @collection_item.collection )
			else
				set_flash 'Collection Item could not be created', :error, @collection_item
				redirect_back fallback_location: '/admin'
			end
		end

		def destroy
			authorize( @collection_item )
			@collection_item.delete
			set_flash 'Collection Item deleted'
			redirect_to edit_collection_admin_path( @collection_item.collection )
		end

		protected

			def model_params
				params.require( :collection_item ).permit(
					:item_polymorphic_id, :collection_id,
				)
			end

			def get_model
				@collection_item = CollectionItem.find( params[:id] )
			end

	end
end
