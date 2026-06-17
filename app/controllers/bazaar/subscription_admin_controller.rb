module Bazaar
	class SubscriptionAdminController < Bazaar::EcomAdminController

		before_action :get_subscription, except: [ :index ]
		before_action :init_search_service, only: [:index]

		def address
			authorize( @subscription )

			address_attributes = params.require( :user_address ).permit( :first_name, :last_name, :geo_country_id, :geo_state_id, :state, :street, :street2, :city, :zip, :phone )
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
			subscription_options[:next_subscription_interval] ||= 1

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

			#@transactions = Bazaar::Transaction.where( parent_obj: ( @subscription.orders.to_a + [ @subscription ] ) ).order( created_at: :desc )

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

			# Filter by pause state. Pause is virtual — stored in
			# properties['paused_until'] (hstore) rather than as a status
			# value — so we apply this filter after the search service.
			case params[:paused]
			when 'true'
				@subscriptions = @subscriptions.where( "(properties->'paused_until')::timestamptz > NOW()" )
			when 'false'
				@subscriptions = @subscriptions.where( "NOT (properties ? 'paused_until') OR (properties->'paused_until')::timestamptz <= NOW()" )
			end

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

			subscription_events = Bunyan::Event.where( target_obj: @subscription )
			order_events = Bunyan::Event.where( target_obj: @subscription.orders )

			@events = Bunyan::Event.where( id: subscription_events.pluck(:id) + order_events.pluck(:id) )
			@events = @events.order( created_at: :desc ).page( params[:page] )

			set_page_meta( title: "Subscription Timeline" )

		end

		def update
			authorize( @subscription )
			@subscription = Subscription.where( id: params[:id] ).includes( :user ).first
			@subscription.attributes = subscription_params
			@subscription.amount = @subscription.price * @subscription.quantity

			if @subscription.save
				
				if @subscription.saved_changes[:status].present? && @subscription.canceled?
					@subscription.subscription_logs.create( subject: 'Subscription Canceled', details: "canceled their subscription" )
					log_event( { name: 'cancel_subscription', user: @subscription.user, category: 'ecom', on: @subscription, content: "canceled #{@subscription.user}'s subscription." } )
					Bazaar::SubscriptionMailer.cancel_subscription( @subscription ).deliver_now
				end
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

			subscription_options = params.require( :subscription ).permit( :offer_id )
			offer = Bazaar::Offer.find( subscription_options.delete( :offer_id ) )

			@subscription_service = Bazaar.subscription_service_class.constantize.new( Bazaar.subscription_service_config )
			@subscription = @subscription_service.subscription_change_offer( @subscription, offer, subscription_options )

			if @subscription.errors.blank?
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

		# Admin-side equivalent of the customer's pause action
		# (Settings::SubscriptionsController#pause). Sets the same four pause
		# properties and pushes next_charged_at out by the selected number of
		# months (1–3). The subscription stays 'active' — pause is virtual.
		def pause
			authorize( @subscription )

			unless @subscription.active? || @subscription.review? || @subscription.hold_review?
				set_flash "Only active subscriptions can be paused.", :danger
				redirect_back fallback_location: edit_subscription_admin_path( @subscription )
				return
			end

			if @subscription.properties.is_a?(Hash) && @subscription.properties['paused_until'].present?
				set_flash "This subscription is already paused.", :danger
				redirect_back fallback_location: edit_subscription_admin_path( @subscription )
				return
			end

			pause_months = params[:pause_for].to_i
			unless (1..3).include?( pause_months )
				set_flash "Please select a pause duration between 1 and 3 months.", :danger
				redirect_back fallback_location: edit_subscription_admin_path( @subscription )
				return
			end

			orig_next_charged_at = @subscription.next_charged_at || Time.now
			new_next_charged_at  = orig_next_charged_at + pause_months.months

			@subscription.next_charged_at = new_next_charged_at
			@subscription.properties ||= {}
			@subscription.properties['paused_at']                = Time.now.iso8601
			@subscription.properties['paused_until']             = new_next_charged_at.iso8601
			@subscription.properties['pre_pause_next_charged_at'] = orig_next_charged_at.iso8601
			@subscription.properties['pause_duration_months']    = pause_months.to_s
			# Re-arm the pause-ending reminder for this fresh pause; a prior pause may
			# have left the flag set (it isn't a PAUSE_PROPERTY_KEY, so it survives
			# natural expiry). Key == SubscriptionPauseEndingNotificationService::SENT_FLAG_KEY.
			@subscription.properties.delete( 'pause_ending_notification_sent_at' )
			@subscription.save!

			pause_duration_label = "#{pause_months} #{'month'.pluralize(pause_months)}"
			# subscription_logs keeps the explicit "(admin)" audit trail of who acted.
			@subscription.subscription_logs.create(
				subject: 'Subscription Paused (admin)',
				details: "admin paused subscription #{@subscription.code} for #{pause_duration_label}, next charge moved from #{orig_next_charged_at} to #{new_next_charged_at}"
			)
			# Bunyan timeline event matches the customer-initiated format:
			# "<customer name> paused subscription <code> for <N months>."
			# Attribute to the subscription's user (not the admin) so the timeline
			# reads consistently with customer pauses; admin attribution lives in
			# the subscription_log above.
			log_event( { name: 'pause_subscription', user: @subscription.user, category: 'ecom', on: @subscription, content: "paused subscription #{@subscription.code} for #{pause_duration_label}." } )

			set_flash "Subscription paused for #{pause_duration_label}. Next charge: #{new_next_charged_at.strftime('%b %d, %Y')}.", :success
			redirect_to edit_subscription_admin_path( @subscription )
		end

		# Admin-side equivalent of the customer's "Resume Subscription" action.
		# Clears the four pause metadata keys from properties and restores
		# next_charged_at to max(pre_pause_next_charged_at, tomorrow) so the
		# subscription resumes normal billing without an immediate retroactive
		# charge. Audit trail is preserved in subscription_logs.
		def unpause
			authorize( @subscription )

			unless @subscription.properties.is_a?(Hash) && @subscription.properties['paused_until'].present?
				set_flash "This subscription is not currently paused.", :danger
				redirect_back fallback_location: edit_subscription_admin_path( @subscription )
				return
			end

			tomorrow = ( Time.now + 1.day ).beginning_of_day
			pre_pause_date = begin
				Time.parse( @subscription.properties['pre_pause_next_charged_at'].to_s )
			rescue ArgumentError, TypeError
				nil
			end
			new_next_charged_at = [pre_pause_date, tomorrow].compact.max

			orig_paused_until = @subscription.properties['paused_until']
			@subscription.next_charged_at = new_next_charged_at
			Bazaar::Subscription::PAUSE_PROPERTY_KEYS.each { |key| @subscription.properties.delete(key) }
			# Also clear the pause-ending reminder flag (not part of PAUSE_PROPERTY_KEYS).
			# Key == SubscriptionPauseEndingNotificationService::SENT_FLAG_KEY.
			@subscription.properties.delete( 'pause_ending_notification_sent_at' )
			@subscription.save!

			@subscription.subscription_logs.create(
				subject: 'Subscription Resumed (admin)',
				details: "admin-resumed subscription #{@subscription.code} (was paused until #{orig_paused_until}), next charge set to #{new_next_charged_at}"
			)
			# Match the customer-initiated timeline format ("<name> resumed subscription <code>.").
			# Attribute to the subscription's user; admin attribution is in the subscription_log above.
			log_event( { name: 'resume_subscription', user: @subscription.user, category: 'ecom', on: @subscription, content: "resumed subscription #{@subscription.code}." } )

			set_flash "Subscription unpaused. Next charge set to #{new_next_charged_at.strftime('%b %d, %Y')}.", :success
			redirect_to edit_subscription_admin_path( @subscription )
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
