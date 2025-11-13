module Bazaar
	class ProductRelationshipAdminController < Bazaar::EcomAdminController

		def create
			authorize( Bazaar::ProductRelationship )

			@related_product = ProductRelationship.new(
				params.require( :product_relationship ).permit( :product_id, :related_product_id, :relationship_type )
			)

			if @related_product.save
				set_flash 'Product Relationship Created'
				redirect_back fallback_location: '/admin'
			else
				set_flash 'Product Relationship could not be created', :error, @related_product
				redirect_back fallback_location: '/admin'
			end
		end

		def destroy
			@related_product = ProductRelationship.find(params[:id])
			authorize( @related_product )
			@related_product.destroy!
			set_flash 'Product Relationship deleted'
			redirect_back fallback_location: '/admin'
		end

	end
end
