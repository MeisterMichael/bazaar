module SwellEcom
	class ProductsController < ApplicationController

		def index
			@products = Product.published
		end

		def show
			
		end
		
	end
end