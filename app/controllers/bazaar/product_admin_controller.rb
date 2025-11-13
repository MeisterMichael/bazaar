module Bazaar
	class ProductAdminController < Bazaar::EcomAdminController

		before_action :get_product, except: [ :create, :index ]
		before_action :init_search_service, only: [:index]

		def index
			authorize( Bazaar::Product )
			sort_by = params[:sort_by] || 'seq'
			sort_dir = params[:sort_dir] || 'asc'

			@search_mode = params[:search_mode] || 'standard'

			filters = ( params[:filters] || {} ).select{ |attribute,value| not( value.nil? ) }
			filters[:status] = params[:status] if params[:status].present?
			@products = @search_service.product_search( params[:q], filters, page: params[:page], order: { sort_by => sort_dir }, mode: @search_mode )

			set_page_meta( title: "Products" )
		end

		def create
			authorize( Bazaar::Product )

			@product = Product.new( product_params )

			@product.publish_at ||= Time.zone.now
			@product.status = 'draft'

			if @product.save
				set_flash 'Product Created'
				redirect_to edit_product_admin_path( @product )
			else
				set_flash 'Product could not be created', :error, @product
				redirect_back fallback_location: '/admin'
			end
		end

		def destroy
			authorize( @product )
			@product.archive!
			set_flash 'Product archived'
			redirect_to product_admin_index_path
		end

		def edit
			authorize( @product )
			set_page_meta( title: "#{@product.title} | Product" )
		end

		def preview
			authorize( @product )

			@product_category = @product.product_category

			@related_products = Product.none

			@related_products = @product_category.products.published.where.not( id: @product.id ).limit(6) if @product_category.present?

			set_page_meta( @product.page_meta )

			add_page_event_data(
				ecommerce: {
					detail: {
						actionField: {},
						products: [ @product.offer.page_event_data ]
					}
				}
			);


			render "bazaar/products/show", layout: 'application'
		end

		def update
			authorize( @product )
			@product.slug = nil if params[:product][:slug_pref].present?

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
				params.require( :product ).permit( [:type, :parent_id, :title, :subtitle, :caption, :slug_pref, :category_id, :description, :medical_disclaimer, :content, :cart_description, :price, :price_as_money_string, :suggested_price, :suggested_price_as_money_string, :status, :availability, :package_shape, :package_weight, :package_length, :package_width, :package_height, :publish_at, :tags, :tags_csv, :avatar, :avatar_attachment, :cover_image, :avatar_urls, :shopify_code, :size_info, :notes, :tax_code, :seq, :sku, :offer_id, :gtins_csv, :mpns_csv, :listing_perkins_page_id, :listing_bogo_perkins_page_id, :listing_recurring_offer_id, :listing_non_recurring_offer_id, :listing_bogo_recurring_offer_id, :listing_bogo_non_recurring_offer_id, :listing_title, :listing_subtitle, :listing_strikethrough_price, :listing_strikethrough_price_as_money, :listing_from_price, :listing_from_price_as_money, :listing_partial, :pre_release_start_at, :pre_release_end_at, :released_at, :badges, :badges_csv, :listing_promotion_perkins_page_id, :listing_promotion_recurring_offer_id, :listing_promotion_non_recurring_offer_id, :listing_promotion_strikethrough_price, :listing_promotion_strikethrough_price_as_money, :listing_promotion_from_price, :listing_promotion_from_price_as_money, :listing_avatar_attachment, :listing_alternative_attachment ] + ( Bazaar.admin_permit_additions[:product_admin] || [] ) )
			end

			def get_product
				@product = Product.friendly.find( params[:id] )
			end

			def init_search_service
				@search_service = Bazaar.search_service_class.constantize.new( Bazaar.search_service_config )
			end

	end
end
