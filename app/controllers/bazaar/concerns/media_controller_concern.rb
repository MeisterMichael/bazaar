module Bazaar
	module Concerns

		module MediaControllerConcern
			extend ActiveSupport::Concern

			included do

			end


			####################################################
			# Class Methods

			module ClassMethods

			end


			####################################################
			# Instance Methods

			def get_bazaar_media( id )
				begin
					@media = Media.friendly.find( id )
					if not( @media.published? )
						raise ActionController::RoutingError.new( 'Not Found' )
					else
						return true
					end
				rescue ActiveRecord::RecordNotFound
					raise ActionController::RoutingError.new( 'Not Found' )
				end

				return false
			end

			def bazaar_render( media )

				set_page_meta( media.page_meta )

				render media.template, layout: media.layout

			end

		end

	end
end
