module Bazaar
	module Concerns

		module MediaAdminControllerConcern
			extend ActiveSupport::Concern

			included do
				before_action :get_bazaar_media, only: [:show,:update,:edit,:destroy,:preview]
			end


			####################################################
			# Class Methods

			module ClassMethods

			end


			####################################################
			# Instance Methods

			def create
				@media = BazaarMedia.new params.require(:bazaar_media).permit(media_param_names)
				@media.user ||= current_user

				if @media.save
					set_flash "Media created!"
					redirect_to edit_bazaar_media_admin_path( @media )
				else
					set_flash "An error occured while trying to create the media", :error, @media
					redirect_back fallback_location: '/admin'
				end
			end

			protected

			def bazaar_render( media )

				set_page_meta( media.page_meta )

				render media.template, layout: media.layout

			end

			def get_bazaar_media
				@media = BazaarMedia.friendly.find( params[:id] )
			end

			def change_media( media )

				media.attributes = params.require(:bazaar_media).permit(media_param_names)

			end


			def media_param_names
				[:title, :subtitle, :avatar_caption, :slug_pref, :description, :content, :category_id, :status, :publish_at, :show_title, :is_commentable, :user_id, :tags, :tags_csv, :redirect_url, :avatar_attachment, :cover_attachment]
			end

		end

	end
end
