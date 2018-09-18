module SwellEcom

	class YourSubscriptionsController < YourController

		before_action :get_subscription, except: [ :index ]

		def destroy
			if @subscription.review? || @subscription.rejected?
				set_flash "Unable to edit a subscription under review"
				redirect_back fallback_location: settings_subscriptions_path
				return false
			end

			@subscription.canceled!

			if @subscription.errors.present?
				set_flash @subscription.errors.full_messages, :danger
			else
				set_flash "Subscription canceled succesfully.", :success
			end

			redirect_back fallback_location: your_subscription_path( @subscription.code )
		end

		def index
			set_page_meta( title: "My Subscriptions" )
			@subscriptions = SwellEcom::Subscription.where( user: current_user ).order( next_charged_at: :desc ).page(params[:page]).per(5)
		end

		def show
			@orders = @subscription.orders.order( created_at: :desc ).page(params[:page]).per(5)
			set_page_meta( title: "Subscription Details \##{@subscription.code} " )
		end

		def edit_shipping_preferences

			@shipping_service = SwellEcom.shipping_service_class.constantize.new( SwellEcom.shipping_service_config )

			@shipping_rates = @shipping_service.find_rates( @subscription )

		end

		def update

			if @subscription.review? || @subscription.rejected?
				set_flash "Unable to edit a subscription under review"
				redirect_back fallback_location: settings_subscriptions_path
				return false
			end

			if ( payment_info = params[:payment_info] ).present?


				if payment_info[:billing_address_attributes].present?

					billing_address_attributes = payment_info.require(:billing_address_attributes).permit( :first_name, :last_name, :geo_country_id, :geo_state_id, :street, :street2, :city, :zip, :phone )
					billing_address = GeoAddress.create( billing_address_attributes.merge( user: current_user ) )

					if billing_address.errors.present?
						set_flash billing_address.errors.full_messages, :danger
						redirect_back fallback_location: '/admin'
						return false
					end

					@subscription.update( billing_address: billing_address )

					log_event( name: 'update_bill_addr', on: @subscription, content: "updated suscription #{@subscription.code} billing info" )

				end

				@subscription_service = SwellEcom.subscription_service_class.constantize.new( SwellEcom.subscription_service_config )

				if @subscription_service.update_payment_profile( @subscription, transaction_options )

					# if subscription was failed, set the status to active and
					# next charge date to now ( if it was set to be charged
					# sometime in the past )
					if @subscription.failed?

						@subscription.status = 'active'
						@subscription.next_charged_at = Time.now if @subscription.next_charged_at < Time.now
						@subscription.save

					end

					log_event( name: 'update_payment', on: @subscription, content: "updated suscription #{@subscription.code} payment details" )

				end

			else

				@subscription.attributes = subscription_attributes

				if ( shipping_address_attributes = subscription_shipping_address_attributes() ).present?
					@subscription.shipping_address = GeoAddress.new( shipping_address_attributes.merge( user: @subscription.user ) )
				end

				# recalculate amounts on change
				@subscription.amount				= @subscription.price * @subscription.quantity
				@subscription.trial_amount	= @subscription.trial_price * @subscription.quantity

				if @subscription.status_changed?
					if @subscription.active?
						log_event( name: 'reactivate_subscription', category: 'ecom', on: @subscription, content: "reactivated suscription #{@subscription.code}" )
					else
						log_event( name: 'cancel_subscription', category: 'ecom', on: @subscription, content: "cancelled suscription #{@subscription.code}" )
					end
				else
					log_event( name: 'update_subscription', category: 'ecom', on: @subscription, content: "updated suscription #{@subscription.code}" )
				end

				log_event( name: 'update_bill_addr', on: @subscription, content: "updated suscription #{@subscription.code} billing info" ) if @subscription.billing_address.changed?
				log_event( name: 'update_ship_addr', on: @subscription, content: "updated suscription #{@subscription.code} shipping info" ) if @subscription.shipping_address.changed?


				@subscription.save

			end

			if @subscription.errors.present?
				set_flash @subscription.errors.full_messages, :danger
			else
				set_flash "Subscription updated succesfully.", :success
			end

			redirect_back fallback_location: your_subscription_path( @subscription.code )

		end

		def update_discount

			if @subscription.review? || @subscription.rejected?
				set_flash "Unable to edit a subscription under review"
				redirect_back fallback_location: settings_subscriptions_path
				return false
			end

			@discount = SwellEcom::Discount.active.in_progress.find_by( code: params[:code].downcase ) if params[:code].present?

			if @discount.present? && @subscription.update( discount: @discount )

				set_flash "Subscription updated succesfully.", :success

			else
				set_flash 'Invalid coupon', :danger
			end

			redirect_back fallback_location: your_subscription_path( @subscription.code )

		end

		private

		def get_subscription
			@subscription = SwellEcom::Subscription.where( user: current_user ).find_by( code: params[:id] )
			raise ActionController::RoutingError.new( 'Not Found' ) unless @subscription.present?
		end

		def subscription_attributes

			attributes = params.require(:subscription).permit(
				:status,
				:next_charged_at,
				:billing_interval_unit,
				:billing_interval_value,
				:shipping_carrier_service_id,
				:quantity,
			).to_h

			attributes.delete(:status) unless ['active','on_hold'].include?( attributes[:status] )
			attributes.delete(:next_charged_at) if attributes[:next_charged_at].blank?
			attributes[:next_charged_at] = "#{attributes[:next_charged_at]} 08:00:00 #{current_user.timezone}" if attributes[:next_charged_at]
			attributes.delete(:billing_interval_unit) unless ['months','days','weeks'].include?( attributes[:billing_interval_unit] )

			attributes
		end

		def subscription_shipping_address_attributes

			attributes = params.require(:subscription).permit(
				{
					:shipping_address_attributes => [ :phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name, ]
				},
			).to_h[:shipping_address_attributes]
		end

		def transaction_options
			params.slice( :stripeToken, :credit_card ).merge({ ip: client_ip, ip_country: client_ip_country })
		end

	end

end
