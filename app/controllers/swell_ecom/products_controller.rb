module SwellEcom
	class ProductsController < ApplicationController

		def buy
			@product = Product.friendly.find( params[:id] )
		end

		def index
			@products = Product.published
		end

		def show
			@product = Product.friendly.find( params[:id] )

			@product_options = @product.product_options

			@min_price = @product.skus.minimum(:price)
			@max_price = @product.skus.maximum(:price)

		end

	end
end
