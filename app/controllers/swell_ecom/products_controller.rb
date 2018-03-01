module SwellEcom

	class ProductsController < ApplicationController
		layout 'swell_ecom/application'

		def index

			if params[:query].present?
				query = { text: params[:query], published?: true, page: params[:page] }

				@title_mod = "found for \"#{params[:query].truncate(20)}\""

				if params[:category].present? && cat = ProductCategory.friendly.find( params[:category] )
					query[:category_id] = cat.id
					@title_mod = "in #{cat.name}"
				end

				@products = Product.record_search query

			else

				@products = Product.published.order( seq: :asc )

				begin
					if params[:category].present? && ( cat = ProductCategory.friendly.find( params[:category] ) ).present?
						@products = @products.where( category_id: cat.id )
						@title_mod = "in #{cat.name}"
					end
				rescue ActiveRecord::RecordNotFound
					set_flash "Category does not exist", :danger
				end

				if params[:tag].present?
					@products = @products.with_any_tags( params[:tag] )
				end

				@products = @products.page( params[:page] )

			end
		end

		def show
			begin
				@product = Product.published.friendly.find( params[:id] )
			rescue ActiveRecord::RecordNotFound => ex
				render '404', status: 404
				return
			end

			@images = SwellMedia::Asset.where( parent_obj: @product, use: 'gallery' ).active

			@product_category = @product.product_category

			@related_products = Product.none

			@related_products = @product_category.products.published.where.not( id: @product.id ).limit(6) if @product_category.present?

			set_page_meta( @product.page_meta )

			add_page_event_data(
				ecommerce: {
					detail: {
						actionField: {},
						products: [ @product.page_event_data ]
					}
				}
			);
		end

	end

end
