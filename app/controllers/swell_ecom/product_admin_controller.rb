module SwellEcom
	class ProductAdminController < SwellMedia::AdminController

		before_action :get_product, except: [ :create, :index ]
		before_action :init_search_service, only: [:index]

		def index
			authorize( SwellEcom::Product, :admin? )
			sort_by = params[:sort_by] || 'seq'
			sort_dir = params[:sort_dir] || 'asc'

			filters = ( params[:filters] || {} ).select{ |attribute,value| not( value.nil? ) }
			filters[:status] = params[:status] if params[:status].present?
			@products = @search_service.product_search( params[:q], filters, page: params[:page], order: { sort_by => sort_dir } )
		end

		def create
			authorize( SwellEcom::Product, :admin_create? )

			@product = Product.new( product_params )
			@product.publish_at ||= Time.zone.now
			@product.status = 'draft'

			if @product.save
				set_flash 'Product Created'
				redirect_to edit_product_admin_path( @product )
			else
				set_flash 'Product could not be created', :error, @product
				redirect_to :back
			end
		end

		def destroy
			authorize( @product, :admin_destroy? )
			@product.archive!
			set_flash 'Product archived'
			redirect_to product_admin_index_path
		end

		def edit
			authorize( @product, :admin_edit? )
			@images = SwellMedia::Asset.where( parent_obj: @product, use: 'gallery' ).active
		end

		def preview
			authorize( @product, :admin_edit? )
			render "products/show", layout: 'application'
		end

		def update
			authorize( @product, :admin_update? )
			@product.slug = nil if params[:product][:title] != @product.title || params[:product][:slug_pref].present?

			params[:product][:price] = params[:product][:price].to_f * 100 #.gsub( /\D/, '' ) if params[:product][:price].present?
			params[:product][:suggested_price] = params[:product][:suggested_price].to_f * 100 #.gsub( /\D/, '' ) if params[:product][:suggested_price].present?
			params[:product][:shipping_price] = params[:product][:shipping_price].to_f * 100 #.gsub( /\D/, '' ) if params[:product][:suggested_price].present?

			@product.attributes = product_params
			@product.avatar_urls = params[:product][:avatar_urls] if params[:product].present? && params[:product][:avatar_urls].present?

			if params[:product][:category_name].present?
				@product.category_id = ProductCategory.where( name: params[:product][:category_name] ).first_or_create( status: 'active' ).id
			end

			if @product.save
				set_flash 'Product Updated'
				redirect_to edit_product_admin_path( id: @product.id )
			else
				set_flash 'Product could not be Updated', :error, @product
				render :edit
			end
		end

		private
			def product_params
				params.require( :product ).permit( :title, :subtitle, :slug_pref, :category_id, :description, :content, :price, :suggested_price, :status, :publish_at, :tags, :tags_csv, :avatar, :avatar_asset_file, :avatar_asset_url, :cover_image, :avatar_urls, :shopify_code, :size_info, :notes, :tax_code, :seq )
			end

			def get_product
				@product = Product.friendly.find( params[:id] )
			end

			def init_search_service
				@search_service = EcomSearchService.new
			end

	end
end
