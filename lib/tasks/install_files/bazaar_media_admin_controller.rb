class BazaarMediaController < ApplicationController
	include Bazaar::Concerns::MediaAdminControllerConcern

	def update

		change_media( @media )

		# make you app specific changes here

		authorize( @media )

		if @media.save && @media.errors.blank?
			set_flash 'Media was Successfully Updated', :success
		else
			set_flash @media.errors.full_messages, :danger
		end

	end

end
