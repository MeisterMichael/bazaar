module SwellEcom
	class ProductOptionsController < SwellMedia::AdminController

		before_filter :get_product_option, except: :create

		def create
			@product_option = ProductOption.create( product_option_params )
			redirect_to :back
		end

		def destroy
			@product_option.destroy
			redirect_to :back
		end

		def update
			@product_option.update( product_option_params )
			redirect_to :back
		end


		private
			def get_product_option
				@product_option = ProductOption.find( params[:id] )
			end

			def product_option_params
				params.require( :product_option ).permit( :product_id, :name, :values_csv )
			end
	end
end