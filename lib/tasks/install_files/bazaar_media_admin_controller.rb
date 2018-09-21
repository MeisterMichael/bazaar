class BazaarMediaAdminController < ApplicationAdminController
	include Bazaar::Concerns::MediaAdminControllerConcern

	def index
		authorize( BazaarMedia )
		sort_by = params[:sort_by] || 'publish_at'
		sort_dir = params[:sort_dir] || 'desc'

		@medias = BazaarMedia.order( "#{sort_by} #{sort_dir}" )

		if params[:status].present? && params[:status] != 'all'
			@medias = eval "@medias.#{params[:status]}"
		end

		if params[:q].present?
			@medias = @medias.where( "array[:q] && keywords", q: params[:q].downcase )
		end

		@medias = @medias.page( params[:page] )
	end

	def preview

		# pulitzer_render renders while handling custom layouts/views
		# via media.layout and media.template
		bazaar_render( @media )

	end

	def update

		change_media( @media )

		# make you app specific changes here

		authorize( @media )

		if @media.save && @media.errors.blank?
			set_flash 'Media was Successfully Updated', :success
		else
			set_flash @media.errors.full_messages, :danger
		end

		redirect_back fallback_location: '/bazaar_media_admin'

	end

end
