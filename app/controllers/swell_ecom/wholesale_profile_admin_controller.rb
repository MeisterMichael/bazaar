module SwellEcom
	class WholesaleProfileAdminController < SwellEcom::EcomAdminController

		before_action :get_wholesale_profile, except: [ :index, :create ]

		def create
			authorize( SwellEcom::WholesaleProfile )

			@wholesale_profile = WholesaleProfile.create( wholesale_profile_params )

			if @wholesale_profile.save

				redirect_to edit_wholesale_profile_admin_path( @wholesale_profile )

			else

				set_flash 'Wholesale profile could not be created', :error, @wholesale_profile
				redirect_back fallback_location: '/admin'

			end

		end

		def destroy
			authorize( @wholesale_profile )
			@wholesale_profile.destroy
			redirect_to wholesale_profile_admin_index_path
		end

		def edit
			authorize( @wholesale_profile )
			set_page_meta( title: "Wholesale Profile" )
		end

		def index
			authorize( SwellEcom::WholesaleProfile )
			sort_by = params[:sort_by] || 'created_at'
			sort_dir = params[:sort_dir] || 'desc'

			@wholesale_profiles = WholesaleProfile.order( "#{sort_by} #{sort_dir}" )

			if params[:status].present? && params[:status] != 'all'
				@wholesale_profiles = eval "@wholesale_profiles.#{params[:status]}"
			end

			@wholesale_profiles = @wholesale_profiles.page( params[:page] )

			set_page_meta( title: "Wholesale Profiles" )
		end


		def update
			authorize( @wholesale_profile )
			@wholesale_profile.attributes = wholesale_profile_params
			@wholesale_profile.save

			set_flash( 'Wholesale profile could not be updated', :error, @wholesale_profile ) if @wholesale_profile.errors.present?

			redirect_back fallback_location: '/admin'
		end

		private
			def wholesale_profile_params
				params.require( :wholesale_profile ).permit(
					:status,
					:title,
					:description,
					:default_profile,
					{
						:wholesale_items_attributes => [
							:id,
							:wholesale_profile_id,
							:item_type,
							:item_id,
							:item_polymorphic_id,
							:price,
							:min_quantity,
							:price_as_money,
						],
					},
				)
			end

			def get_wholesale_profile
				@wholesale_profile = WholesaleProfile.find_by( id: params[:id] )
			end

	end
end
