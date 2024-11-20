module Bazaar
	class OfferAdminController < Bazaar::EcomAdminController

		before_action :get_offer, except: [:index,:new,:create]
		before_action :init_search_service, only: [:index]
		before_action :offer_templates, only: [:edit]


		def copy

			has_many_relations = [[:offer_prices, :parent_obj], [:offer_schedules, :parent_obj], [:offer_skus, :parent_obj]]
			has_many_attached_relations = []
			has_one_attached_relations = [:avatar_attachment]


			original = Bazaar::Offer.find params[:id]


			copy = original.dup
			copy.attributes = offer_params
			copy.save!


			has_many_relations.each do |row|
				relation_name = row.first
				foreign_key = row.second
				original.try(relation_name).each do |ogrelation|
					ogrelation.dup.update( foreign_key => copy )
				end
			end

			has_many_attached_relations.each do |relation_name|
				original.try(relation_name).each do |ogrelation|
					copy.try(relation_name).attach( ogrelation.blob )
				end
			end

			has_one_attached_relations.each do |relation_name|
				copy.try(relation_name).attach( original.try(relation_name).blob ) if original.try(relation_name).attached?
			end


			if not( copy.errors.present? )
				set_flash "Offer created!"
				redirect_to edit_offer_admin_path( copy )
			else
				set_flash "An error occured while trying to create the offer", :error, copy
				redirect_back fallback_location: '/admin'
			end
		end


		def create
			authorize( Bazaar::Offer )

			@offer = Bazaar::Offer.new( offer_params )
			@offer.cart_title ||= @offer.title


			if params[:price_as_money].present? && params[:sku_id].present?
				@offer.offer_prices.new( price_as_money_string: params[:price_as_money], status: 'active', start_interval: 1, max_intervals: nil ) if params[:price_as_money]
				@offer.offer_schedules.new( status: 'active', start_interval: 1, max_intervals: 1, interval_value: 0, interval_unit: 'weeks' )
				@offer.offer_skus.new( sku_id: params[:sku_id], status: 'active', start_interval: 1, max_intervals: nil ) if params[:sku_id]
			else
				offer_config_update(@offer)
			end

			if @offer.save
				set_flash 'Offer created'
				redirect_to edit_offer_admin_path( @offer.id )
			else
				set_flash 'Offer could not be created', :error, @offer
				redirect_back fallback_location: offer_admin_index_path()
			end
		end

		def destroy
			authorize( @offer )
			if @offer.trash!
				set_flash "Sku removed", :success
				redirect_back fallback_location: offer_admin_index_path()
			else
				set_flash @offer.errors.full_messages, :danger
				redirect_back fallback_location: offer_admin_index_path()
			end
		end

		def edit
			authorize( @offer )
			set_page_meta( title: "#{@offer.title} - Offers" )

			@has_orders = Bazaar::OrderOffer.where( offer: @offer ).joins(:order).merge(Bazaar::Order.positive_status).present?
		end

		def index
			authorize( Bazaar::Offer )

			sort_by = params[:sort_by] || 'title'
			sort_dir = params[:sort_dir] || 'asc'

			filters = ( params[:filters] || {} ).select{ |attribute,value| not( value.nil? ) }
			params[:status] ||= 'active'
			filters[ params[:status] ] = true if params[:status].present? && params[:status] != 'all'
			@offers = @search_service.offer_search( params[:q], filters, page: params[:page], order: { sort_by => sort_dir }, mode: params[:search_mode] )

			set_page_meta( title: "Offers" )

			respond_to do |format|
				format.json {
				}
				format.html {
				}
			end
		end

		def update
			authorize( @offer )

			@offer.attributes = offer_params

			offer_config_update(@offer, save: true )

			if @offer.save
				set_flash "Offer Updated", :success
			else
				set_flash @offer.errors.full_messages, :danger
			end
			redirect_back fallback_location: offer_admin_index_path()
		end

		protected
		def offer_templates
			@offer_price_template = 'first_thereafter' if @offer.offer_prices.active.where( start_interval: 1, max_intervals: nil ).count + @offer.offer_prices.active.where( start_interval: 1, max_intervals: 1 ).count + @offer.offer_prices.active.where( start_interval: 2, max_intervals: nil ).count <= 2

			@offer_schedule_template = 'single_duration' if @offer.offer_schedules.active.count <= 1

			@offer_sku_template = "first_thereafter" if @offer.offer_skus.active.count - (@offer.offer_skus.active.where( start_interval: 1, max_intervals: nil ).count + @offer.offer_skus.active.where( start_interval: 1, max_intervals: 1 ).count + @offer.offer_skus.active.where( start_interval: 2, max_intervals: nil ).count) == 0
		end

		def get_offer
			@offer = Bazaar::Offer.find params[:id]
		end

		def offer_params
			params.require(:offer).permit( [:status, :availability, :title, :avatar, :avatar_attachment, :code, :tax_code, :suggested_price, :suggested_price_as_money_string, :suggested_price_as_money, :description, :cart_title, :cart_description, :disclaimer, :product_id, :min_quantity, :tags_csv] + ( Bazaar.admin_permit_additions[:offer_admin] || [] ) )
		end

		def offer_config_params
			return {} if params[:offer_config].blank?
			return params.require(:offer_config).permit( offer_prices: {}, offer_schedules: {}, offer_skus: {} )
		end

		def offer_config_update(offer, options = {})
			offer_prices = []
			offer_schedules = []
			offer_skus = []

			if (offer_configs = offer_config_params).present?

				recurring_offer = false

				if offer_configs[:offer_schedules]
					offer_configs[:offer_schedules] = offer_configs[:offer_schedules].values

					offer_configs[:offer_schedules].each do |attributes|

						offer_schedule = offer.offer_schedules.where( id: attributes[:id] ).first if attributes[:id].present?
						offer_schedule ||= offer.offer_schedules.active.where( start_interval: attributes[:start_interval] ).first_or_initialize
						offer_schedule.attributes = attributes
						offer_schedule.max_intervals = ( offer_schedule.interval_value == 0 ? 1 : nil )
						offer_schedules << offer_schedule

					end

					# Remove any offer.offer_schedules not in offer_schedules
					offer.offer_schedules.active.each do |offer_schedule|
						unless offer_schedules.find{|os| os.id == offer_schedule.id }.present?
							offer_schedule.status = 'trash'
							offer_schedules << offer_schedule
						end
					end

					recurring_offer = offer_schedules.collect(&:max_intervals).select(&:present?).blank?
				else
					recurring_offer = offer.offer_schedules.to_a.collect(&:max_intervals).select(&:present?).blank?
				end



				if offer_configs[:offer_prices]
					offer_configs[:offer_prices] = offer_configs[:offer_prices].values

					offer_configs[:offer_prices].each do |attributes|
						
						if attributes[:price_as_money_string].present? && ( recurring_offer || attributes[:start_interval].to_i == 1)

							offer_price = offer.offer_prices.where( id: attributes[:id] ).first if attributes[:id].present?
							offer_price ||= offer.offer_prices.active.where( start_interval: attributes[:start_interval] ).first_or_initialize
							offer_price.attributes = attributes
							offer_prices << offer_price
						end

					end

					# de-dup

					# remove max_intervals on last IF is recurring... as a price is needed
					offer_prices.last.max_intervals = nil if recurring_offer

					# Remove any offer.offer_prices not in offer_prices
					offer.offer_prices.active.each do |offer_price|
						unless offer_prices.find{|op| op.id == offer_price.id }.present?
							offer_price.status = 'trash'
							offer_prices << offer_price
						end
					end
				end

				if offer_configs[:offer_skus]
					offer_configs[:offer_skus] = offer_configs[:offer_skus].values

					previous_attributes = {}
					offer_configs[:offer_skus].each do |attributes|

						if attributes[:start_interval].to_i == 2
							attributes[:sku_id] = previous_attributes[:sku_id] if attributes[:sku_id].blank?
							# attributes[:quantity] = previous_attributes[:quantity] if attributes[:quantity].blank?
						end

						if attributes[:sku_id].present? && attributes[:quantity].blank? && attributes[:start_interval].to_i == 2 && recurring_offer && offer_skus.last.sku.id == attributes[:sku_id].to_i
							offer_skus.last.max_intervals = nil
						elsif attributes[:sku_id].present? && attributes[:quantity].to_i > 0
							
							offer_sku_id = attributes.delete(:id).presence
							offer_sku = offer.offer_skus.where( id: offer_sku_id ).first if offer_sku_id.present?
							
							if offer_sku.blank?
								offer_sku = offer.offer_skus.active.where( start_interval: attributes[:start_interval], sku_id: attributes[:sku_id] ).first_or_initialize
							end
							
							offer_sku.attributes = attributes
							offer_skus << offer_sku

						end

						previous_attributes = attributes
					end

					# Remove any offer.offer_skus not in offer_skus
					offer.offer_skus.active.each do |offer_sku|
						unless offer_skus.find{|os| os.id == offer_sku.id }.present?
							offer_sku.status = 'trash'
							offer_skus << offer_sku
						end
					end
				end
			end

			if options[:save]
				offer_prices.collect(&:save)
				offer_schedules.collect(&:save)
				offer_skus.collect(&:save)
			end
		end

		def init_search_service
			@search_service = Bazaar.search_service_class.constantize.new( Bazaar.search_service_config )
		end
	end
end
