module SwellEcom
	class ProductVariantsController < SwellMedia::AdminController

		def create
			@product = Product.find( params[:product_id] )
			params[:option_value].split( /,/ ).reverse.each do |value|
				@product.product_variants.create( option_name: params[:option_name], option_value: value.strip )
			end
			redirect_back fallback_location: '/admin'
		end

		def destroy
			@variant = ProductVariant.friendly.find( params[:id] )
			@variant.destroy
			redirect_back fallback_location: '/admin'
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
				#pv.publish_at = @product.publish_at
				pv.save
			end

			redirect_back fallback_location: '/admin'
		end

		def update
			@variant = ProductVariant.friendly.find( params[:id] )
			params[:product_variant][:price] = params[:product_variant][:price].to_f * 100
			@variant.update( variant_params )
			redirect_back fallback_location: '/admin'
		end

		private
			def variant_params
				params.require( :product_variant ).permit( :title, :option_name, :option_value, :seq, :price, :shipping_price, :inventory, :description, :avatar, :status )
			end

	end
end