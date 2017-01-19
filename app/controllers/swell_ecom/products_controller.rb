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
		end
		
	end
end