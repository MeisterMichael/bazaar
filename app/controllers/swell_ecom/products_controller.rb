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
			@skus = @product.skus
			#@skus = []
			#
			#@product_options = @product.product_options
			#@options = {}
			#@product.skus.each do |sku|
			#	sku.options.each do |code, value|
			#		@options[code] ||= { values: [], selected: ((params[:option]||{})[code.to_sym] || '') }
			#		@options[code][:values] = @options[code][:values] + [value]
			#	end
			#
			#	@skus << sku if sku.options.select{|code,value| value == @options[code][:selected]}.count == sku.options.count
			#
			#end
			#
			@min_price = @skus.minimum(:price)
			@max_price = @skus.maximum(:price)

		end

	end
end
