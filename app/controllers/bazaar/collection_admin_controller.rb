module Bazaar
	class CollectionAdminController < Bazaar::EcomAdminController
		before_action :get_model, except: [ :create, :index ]

		def create
			authorize( Bazaar::Collection )

			@collection = Collection.new( model_params )

			if @collection.save
				set_flash 'Collection Created'
				redirect_to edit_collection_admin_path( @collection )
			else
				set_flash 'Collection could not be created', :error, @collection
				redirect_back fallback_location: '/admin'
			end
		end

		def destroy
			authorize( @collection )
			@collection.archive!
			set_flash 'Collection archived'
			redirect_to collection_admin_index_path
		end

		def edit
			authorize( @collection )
			set_page_meta( title: "#{@collection.title} | Collection" )
		end


		def index
			authorize( Bazaar::Collection )

			sort_by = params[:sort_by] || 'created_at'
			sort_dir = params[:sort_dir] || 'desc'

			@collections = Collection.where.not( status: 'archived' )
			@collections = @collections.order( sort_by => sort_dir )
			@collections = @collections.page( params[:page] ).per( params[:per] )

			set_page_meta( title: "Collections" )
		end

		def update
			authorize( @collection )

			@collection.attributes = model_params
			@collection.slug = nil if params[:collection][:slug_pref].present?

			if @collection.save
				set_flash "Collection Updated", :success
			else
				set_flash @collection.errors.full_messages, :danger
			end
			redirect_to edit_collection_admin_path( @collection )
		end

		protected

			def model_params
				params.require( :collection ).permit(
					:title, :status, :collection_type, :availability, :slug_pref,
					collection_items_attributes: [ :id, :item_polymorphic_id, :item_id, :item_type, :seq ],
				)
			end

			def get_model
				@collection = Collection.friendly.find( params[:id] )
			end

	end
end
