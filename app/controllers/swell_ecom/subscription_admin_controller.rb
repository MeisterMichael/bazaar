module SwellEcom
	class SubscriptionAdminController < SwellEcom::EcomAdminController

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

		def create
			user = SwellMedia.registered_user_class.constantize.find( params[:user_id] )

			subscription_options = params.require(:subscription).permit(
				:trial_price,
				:price,
				:quantity,
				:subscription_plan,
				{
					:shipping_address_attributes => [
						:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name,
					],
					:billing_address_attributes => [
						:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name,
					],
				},
			).to_h

			subscription_options[:shipping_address]	= SwellEcom::GeoAddress.new( subscription_options.delete(:shipping_address_attributes) ) if subscription_options[:shipping_address_attributes].present?
			subscription_options[:billing_address]	= SwellEcom::GeoAddress.new( subscription_options.delete(:billing_address_attributes) ) if subscription_options[:billing_address_attributes].present?
			subscription_options[:shipping_address] ||= subscription_options[:billing_address]
			subscription_options[:billing_address]	||= subscription_options[:shipping_address]

			subscription_options[:trial_price]		= subscription_options[:trial_price].to_i if subscription_options[:trial_price]
			subscription_options[:price]			= subscription_options[:price].to_i if subscription_options[:price]
			subscription_options[:quantity]			= subscription_options[:quantity].to_i if subscription_options[:quantity]

			plan = SwellEcom::SubscriptionPlan.find( subscription_options.delete( :subscription_plan ) )

			puts JSON.pretty_generate subscription_options
			puts JSON.pretty_generate subscription_options[:shipping_address].to_json
			puts JSON.pretty_generate subscription_options[:billing_address].to_json

			@subscription_service = SwellEcom.subscription_service_class.constantize.new( SwellEcom.subscription_service_config )
			@subscription = @subscription_service.subscribe( user, plan, subscription_options )

			if @subscription.errors.present?
				redirect_back fallback_location: '/admin'
			else
				@subscription.update( next_charged_at: Time.now ) # start the first charge now!

				redirect_to swell_ecom.edit_subscription_admin_path( @subscription )
			end

		end

		def edit
			authorize( @subscription, :admin_edit? )
			@orders = Order.where( parent: @subscription ).order( created_at: :desc )

			@transactions = SwellEcom::Transaction.where( parent_obj: ( @subscription.orders.to_a + [ @subscription ] ) ).order( created_at: :desc )

			set_page_meta( title: "#{@subscription.code} | Subscription" )
		end

		def edit_shipping_carrier_service

			@shipping_service = SwellEcom.shipping_service_class.constantize.new( SwellEcom.shipping_service_config )

			@shipping_rates = @shipping_service.find_rates( @subscription )

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

		def new
			@subscription = SwellEcom::Subscription.new( shipping_address: SwellEcom::GeoAddress.new, billing_address: SwellEcom::GeoAddress.new )
			@user = SwellMedia.registered_user_class.constantize.find( params[:user_id] )
		end

		def payment_profile
			authorize( @subscription, :admin_update? )

			@subscription_service = SwellEcom.subscription_service_class.constantize.new( SwellEcom.subscription_service_config )

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

			if params[:redirect_to] == 'edit'
				redirect_to edit_subscription_admin_path( @subscription )
			else
				redirect_back fallback_location: '/admin'
			end
		end

		private
			def subscription_params
				params.require( :subscription ).permit( :next_charged_at, :shipping_carrier_service_id, :quantity, :price_as_money, :trial_price_as_money, :billing_interval_value, :billing_interval_unit, :status, :discount_id, user_attributes: [ :first_name, :last_name, :email ] )
			end

			def get_subscription
				@subscription = Subscription.find_by( id: params[:id] )
			end

			def init_search_service
				@search_service = EcomSearchService.new
			end

	end
end
