module SwellEcom
	class ProductVariantsController < SwellMedia::AdminController

		def create
			
		end

		def destroy
			@variant = ProductVariant.find( params[:id] )
			@variant.destroy
			redirect_to :back
		end
		
		def generate
			@product = Product.find( params[:id] )
			variants = []
			@product.product_options.each do |option|
				if variants.empty?
					variants = option.values.collect{ |v| {option.name => v} } # "#{option.name}: #{v}" }
				else
					variants = variants.product( option.values.collect{ |v| {option.name => v} } ) # "#{option.name}: #{v}" } )
				end
			end

			variants.each do |vars|
				pv = @product.product_variants.new
				vars.each do |pair|
					pair.each do |name, value|
						pv.options[name] = value
					end
				end
				pv.title = @product.title
				pv.options.each{ |opt| pv.title += " | #{opt[0]} #{opt[1]}" }
				pv.price = @product.price
				pv.shipping_price = @product.shipping_price
				pv.description = @product.description
				pv.publish_at = @product.publish_at
				pv.save
			end

			redirect_to :back
		end

	end
end