module Bazaar
	class CollectionItemAdminController < Bazaar::EcomAdminController
		before_action :get_model, except: [ :create, :index ]

		def create
			authorize( Bazaar::CollectionItem )

			@collection_item = CollectionItem.new( model_params )

			@collection_item.seq = @collection_item.collection.collection_items.maximum(:seq).to_i + 1 if @collection_item.seq.nil?

			if @collection_item.save

				resequnce

				set_flash 'Collection Item Created'
				redirect_to edit_collection_admin_path( @collection_item.collection )
			else
				set_flash 'Collection Item could not be created', :error, @collection_item
				redirect_back fallback_location: '/admin'
			end
		end

		def destroy
			authorize( @collection_item )

			if @collection_item.save

				@collection_item.collection.collection_items.where( "seq >= ?", @collection_item.seq ).where.not( id: @collection_item.id ).update_all( "seq = seq + 1" )

				resequnce

				set_flash 'Collection Item Updated'
			else
				set_flash 'Collection Item could not be updated', :error, @collection_item
			end

			redirect_to edit_collection_admin_path( @collection_item.collection )
		end

		def update
			authorize( @collection_item )
			@collection_item.save
			set_flash 'Collection Item deleted'
			redirect_to edit_collection_admin_path( @collection_item.collection )
		end

		protected

			def resequnce
				@collection_item.collection.collection_items.order(seq: :asc).each_with_index do |a_collection_item, i|
					a_collection_item.seq = i + 1
					a_collection_item.save
				end
			end

			def model_params
				params.require( :collection_item ).permit(
					:item_polymorphic_id, :item_id, :item_type, :collection_id, :seq
				)
			end

			def get_model
				@collection_item = CollectionItem.find( params[:id] )
			end

	end
end
