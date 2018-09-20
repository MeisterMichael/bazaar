class BazaarMediaController < ApplicationController
	include Bazaar::Concerns::MediaControllerConcern

	def index
		@medias = BazaarMedia.published.order( title: :asc, created_at: :asc )
		@medias = @medias.page( params[:page] ).per( params[:per] || 10 )

		set_page_meta(
			{
			title: "Shop - #{Pulitzer.app_name}",
			description: "Shop at #{Pulitzer.app_name}",
			fb_type: 'article'
			}
		)
	end

	def show

		# get_pulitzer_media is a wrapper on friendly_id that also
		# handles special cases such as the sitemap & handling redirects
		return unless get_bazaar_media( params[:id] )

		# pulitzer_render renders while handling custom layouts/views
		# via media.layout and media.template
		bazaar_render( @media )

	end

end
