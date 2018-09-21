module Bazaar
	module Concerns

		module MediaControllerConcern
			extend ActiveSupport::Concern

			included do
				before_action :get_bazaar_media, only: [:show,:update,:edit,:destroy]
			end


			####################################################
			# Class Methods

			module ClassMethods

			end


			####################################################
			# Instance Methods

			protected
			def get_bazaar_media
				@media = Media.friendly.find( params[:id] )
			end

			def change_media( media )
				
				media_params = params.require(:media).permit(media_param_names)

				media.slug = nil if media_params[:slug_pref]
				media.atttributes = media_params

			end


			def media_param_names
				[:title, :subtitle, :avatar_caption, :slug_pref, :description, :content, :category_id, :status, :publish_at, :show_title, :is_commentable, :user_id, :tags, :tags_csv, :redirect_url, :avatar_attachment, :cover_attachment]
			end

		end

	end
end
