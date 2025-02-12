module Bazaar
	class SubscriptionAdminController < Bazaar::EcomAdminController

		before_action :get_subscription, except: [ :index ]
		before_action :init_search_service, only: [:index]

		def address
			authorize( @subscription )

			address_attributes = params.require( :user_address ).permit( :first_name, :last_name, :geo_country_id, :geo_state_id, :street, :street2, :city, :zip, :phone )
			address = UserAddress.canonical_find_or_create_with_cannonical_geo_address( address_attributes.merge( user: @subscription.user ) )

			if address.errors.present?

				set_flash address.errors.full_messages, :danger

			else

				user_address_attribute_name = params[:attribute] == 'billing_user_address' ? 'billing_user_address' : 'shipping_user_address'
				geo_address_attribute_name = user_address_attribute_name.gsub(/user_/,'')

				# @todo trash the old address if it's no long used by any orders or subscriptions
				@subscription.update(
					user_address_attribute_name => address,
					geo_address_attribute_name => address.geo_address
				)

				if @subscription.errors.present?
					set_flash address.errors.full_messages, :danger
				else
					set_flash "Address Updated", :success
				end

			end
			redirect_back fallback_location: '/admin'
		end

		def create
			user = User.find( params[:user_id] )

			subscription_options = params.require(:subscription).permit(
				:shipping,
				:tax,
				:price,
				:quantity,
				:offer_id,
				{
					:shipping_user_address_attributes => [
						:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name,
					],
					:billing_user_address_attributes => [
						:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name,
					],
				},
			).to_h

			subscription_options[:shipping_user_address]	= UserAddress.canonical_find_or_new_with_cannonical_geo_address( subscription_options.delete(:shipping_user_address_attributes) ) if subscription_options[:shipping_user_address_attributes].present?
			subscription_options[:billing_user_address]	= UserAddress.canonical_find_or_new_with_cannonical_geo_address( subscription_options.delete(:billing_user_address_attributes) ) if subscription_options[:billing_user_address_attributes].present?
			subscription_options[:shipping_user_address] ||= subscription_options[:billing_user_address]
			subscription_options[:billing_user_address]	||= subscription_options[:shipping_user_address]

			subscription_options[:shipping_user_address].user	= user
			subscription_options[:billing_user_address].user	= user

			subscription_options[:price]						= subscription_options[:price].to_i if subscription_options[:price]
			subscription_options[:quantity]					= subscription_options[:quantity].to_i if subscription_options[:quantity]
			subscription_options[:shipping]					||= 0
			subscription_options[:tax]							||= 0

			offer = Bazaar::Offer.find( subscription_options.delete( :offer_id ) )

			@subscription_service = Bazaar.subscription_service_class.constantize.new( Bazaar.subscription_service_config )
			@subscription = @subscription_service.subscribe( user, offer, subscription_options )

			if @subscription.errors.present?
				redirect_back fallback_location: '/admin'
			else
				@subscription.update( next_charged_at: 15.minutes.from_now ) # start the first charge now!

				redirect_to bazaar.edit_subscription_admin_path( @subscription )
			end

		end

		def edit
			authorize( @subscription )
			@orders = @subscription.orders.order( created_at: :desc )

			@transactions = Bazaar::Transaction.where( parent_obj: ( @subscription.orders.to_a + [ @subscription ] ) ).order( created_at: :desc )

			set_page_meta( title: "#{@subscription.code} | Subscription" )
		end

		def edit_shipping_carrier_service

			@shipping_service = Bazaar.shipping_service_class.constantize.new( Bazaar.shipping_service_config )
			@subscription_service = Bazaar.subscription_service_class.constantize.new( Bazaar.subscription_service_config )

			@order = @subscription_service.generate_subscription_order( @subscription )

			@shipping_rates = @shipping_service.find_rates( @order )

		end

		def index
			authorize( Bazaar::Subscription )
			sort_by = params[:sort_by] || 'created_at'
			sort_dir = params[:sort_dir] || 'desc'

			@search_mode = params[:search_mode] || 'standard'

			filters = ( params[:filters] || {} ).select{ |attribute,value| not( value.nil? ) }
			filters[ params[:status] ] = true if params[:status].present? && params[:status] != 'all'
			@subscriptions = @search_service.subscription_search( params[:q], filters, page: params[:page], order: { sort_by => sort_dir }, mode: @search_mode )

			set_page_meta( title: "Subscriptions" )
		end

		def new
			@user = User.find( params[:user_id] )

			@subscription = Bazaar::Subscription.new(
				shipping_user_address: UserAddress.new(
					user: @user,
					first_name: @user.first_name,
					last_name: @user.last_name,
				),
				billing_user_address: UserAddress.new(
					user: @user,
					first_name: @user.first_name,
					last_name: @user.last_name,
				),
			)
		end

		def payment_profile
			authorize( @subscription )

			@subscription_service = Bazaar.subscription_service_class.constantize.new( Bazaar.subscription_service_config )

			address_attributes = params.require( :subscription ).require( :billing_user_address_attributes ).permit( :first_name, :last_name, :geo_country_id, :geo_state_id, :street, :street2, :city, :zip, :phone )
			address = UserAddress.canonical_find_or_create_with_cannonical_geo_address( address_attributes.merge( user: @subscription.user ) )

			if address.errors.present?

				set_flash address.errors.full_messages, :danger

			else

				@subscription.billing_user_address = address
				@subscription.billing_address = address.geo_address

				@subscription_service.update_payment_profile( @subscription, credit_card: params[:credit_card] )

				if @subscription.errors.present?

					set_flash @subscription.errors.full_messages, :danger

				else

					set_flash "Payment Profile Updated", :success

				end

			end

			redirect_back fallback_location: '/admin'
		end

		def timeline
			authorize( @subscription )

			@events = Bunyan::Event.where( target_obj: @subscription )
			@events = @events.or( Bunyan::Event.where( target_obj: @subscription.orders ) )
			@events = @events.or( Bunyan::Event.where( user_id: @subscription.user_id, created_at: Time.at(0)..(@subscription.created_at + 10.minutes) ) )
			@events = @events.where( category: [ 'account', 'ecom' ] )
			@events = @events.order( created_at: :desc ).page( params[:page] )

			set_page_meta( title: "Subscription Timeline" )

		end

		def update
			authorize( @subscription )
			@subscription = Subscription.where( id: params[:id] ).includes( :user ).first
			@subscription.attributes = subscription_params
			@subscription.amount = @subscription.price * @subscription.quantity

			if @subscription.save
				log_event( { name: 'cancel_subscription', user: @subscription.user, category: 'ecom', on: @subscription, content: "canceled #{@subscription.user}'s subscription." } ) if @subscription.saved_changes[:status].present? && @subscription.canceled?
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

		def update_offer
			authorize( @subscription )
			@subscription = Subscription.where( id: params[:id] ).includes( :user ).first
			@subscription.attributes = params.require( :subscription ).permit( :offer_id )
			@subscription.price = @subscription.offer.price_for_interval( @subscription.next_subscription_interval )
			@subscription.amount = @subscription.price * @subscription.quantity

			if @subscription.save
				set_flash "Subscription Offer updated successfully", :success

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
				params.require( :subscription ).permit( :next_charged_at, :shipping_carrier_service_id, :quantity, :price_as_money, :billing_interval_value, :billing_interval_unit, :status, :discount_id, user_attributes: [ :first_name, :last_name, :email ] )
			end

			def get_subscription
				@subscription = Subscription.find_by( id: params[:id] )
			end

			def init_search_service
				@search_service = Bazaar.search_service_class.constantize.new( Bazaar.search_service_config )
			end

	end
end
