module SwellEcom
	class SubscriptionAdminController < SwellMedia::AdminController


		before_action :get_subscription, except: [ :index ]
		before_action :init_search_service, only: [:index]

		def address
			authorize( @subscription, :admin_update? )

			address_attributes = params.require( :geo_address ).permit( :first_name, :last_name, :geo_country_id, :geo_state_id, :street, :street2, :city, :zip, :phone )
			address = GeoAddress.create( address_attributes.merge( user: @subscription.user ) )

			if address.errors.present?

				set_flash address.errors.full_messages, :danger

			else

				attribute_name = params[:attribute] == 'billing_address' ? 'billing_address' : 'shipping_address'
				# @todo trash the old address if it's no long used by any orders or subscriptions
				@subscription.update( attribute_name => address )

				set_flash "Address Updated", :success

			end
			redirect_back fallback_location: '/admin'
		end

		def edit
			authorize( @subscription, :admin_edit? )
			@orders = Order.where( parent: @subscription ).order( created_at: :desc )

			@billing_countries 	= SwellEcom::GeoCountry.all
			@shipping_countries = SwellEcom::GeoCountry.all

			@billing_countries = @billing_countries.where( abbrev: SwellEcom.billing_countries[:only] ) if SwellEcom.billing_countries[:only].present?
			@billing_countries = @billing_countries.where( abbrev: SwellEcom.billing_countries[:except] ) if SwellEcom.billing_countries[:except].present?

			@shipping_countries = @shipping_countries.where( abbrev: SwellEcom.shipping_countries[:only] ) if SwellEcom.shipping_countries[:only].present?
			@shipping_countries = @shipping_countries.where( abbrev: SwellEcom.shipping_countries[:except] ) if SwellEcom.shipping_countries[:except].present?

			@billing_states 	= SwellEcom::GeoState.where( geo_country_id: @subscription.shipping_address.try(:geo_country_id) || @billing_countries.first.id ) if @billing_countries.count == 1
			@shipping_states	= SwellEcom::GeoState.where( geo_country_id: @subscription.billing_address.try(:geo_country_id) || @shipping_countries.first.id ) if @shipping_countries.count == 1

			set_page_meta( title: "#{@subscription.code} | Subscription" )
		end

		def index
			authorize( SwellEcom::Subscription, :admin? )
			sort_by = params[:sort_by] || 'created_at'
			sort_dir = params[:sort_dir] || 'desc'


			filters = ( params[:filters] || {} ).select{ |attribute,value| not( value.nil? ) }
			filters[ params[:status] ] = true if params[:status].present? && params[:status] != 'all'
			@subscriptions = @search_service.subscription_search( params[:q], filters, page: params[:page], order: { sort_by => sort_dir } )

			set_page_meta( title: "Subscriptions" )
		end

		def payment_profile
			authorize( @subscription, :admin_update? )

			@subscription_service = SwellEcom::SubscriptionService.new

			address_attributes = params.require( :subscription ).require( :billing_address_attributes ).permit( :first_name, :last_name, :geo_country_id, :geo_state_id, :street, :street2, :city, :zip, :phone )
			address = GeoAddress.create( address_attributes.merge( user: @subscription.user ) )

			if address.errors.present?

				set_flash address.errors.full_messages, :danger

			else

				@subscription.billing_address = address

				@subscription_service.update_payment_profile( @subscription, credit_card: params[:credit_card] )

				if @subscription.errors.present?

					set_flash @subscription.errors.full_messages, :danger

				else

					set_flash "Payment Profile Updated", :success

				end

			end

			redirect_back fallback_location: '/admin'
		end

		def update
			authorize( @subscription, :admin_update? )
			@subscription = Subscription.where( id: params[:id] ).includes( :user ).first
			@subscription.attributes = subscription_params
			@subscription.trial_amount = @subscription.trial_price * @subscription.quantity
			@subscription.amount = @subscription.price * @subscription.quantity

			if @subscription.save
				set_flash "Subscription updated successfully", :success

			else

				set_flash @subscription.errors.full_messages, :danger

			end


			redirect_back fallback_location: '/admin'
		end

		private
			def subscription_params
				params.require( :subscription ).permit( :next_charged_at, :quantity, :price_as_money, :trial_price_as_money, :billing_interval_value, :billing_interval_unit, :status, user_attributes: [ :first_name, :last_name, :email ] )
			end

			def get_subscription
				@subscription = Subscription.find_by( id: params[:id] )
			end

			def init_search_service
				@search_service = EcomSearchService.new
			end

	end
end
