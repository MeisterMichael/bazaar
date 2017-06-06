module SwellEcom
	class ProductAdminController < SwellMedia::AdminController

		before_filter :get_product, except: [ :create, :index ]

		def index
			sort_by = params[:sort_by] || 'publish_at'
			sort_dir = params[:sort_dir] || 'desc'

			@products = Product.order( "#{sort_by} #{sort_dir}" )

			if params[:status].present? && params[:status] != 'all'
				@products = eval "@products.#{params[:status]}"
			end

			if params[:q].present?
				@products = @products.where( "array[:q] && keywords", q: params[:q].downcase )
			end

			@products = @products.page( params[:page] )
		end

		def create
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
			@product.archive!
			set_flash 'Product archived'
			redirect_to product_admin_index_path
		end

		def edit
			@images = SwellMedia::Asset.where( parent_obj: @product, use: 'gallery' ).active
		end

		def preview
			render "products/show", layout: 'application'
		end

		def update
			@product.slug = nil if params[:update_slug].present? && params[:product][:title] != @product.title

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
				params.require( :product ).permit( :title, :subtitle, :slug_pref, :category_id, :description, :content, :price, :suggested_price, :status, :publish_at, :tags, :tags_csv, :avatar, :avatar_asset_file, :avatar_asset_url, :cover_image, :avatar_urls, :shopify_code, :size_info, :notes, :tax_code )
			end

			def get_product
				@product = Product.friendly.find( params[:id] )
			end

	end
end
