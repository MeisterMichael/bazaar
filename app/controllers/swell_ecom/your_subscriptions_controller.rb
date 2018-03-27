module SwellEcom

	class YourSubscriptionsController < YourController

		before_action :get_subscription, except: [ :index ]

		def destroy

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

		def update

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

				end

				@subscription_service = SubscriptionService.new

				if @subscription_service.update_payment_profile( @subscription, transaction_options )

					# if subscription was failed, set the status to active and
					# next charge date to now ( if it was set to be charged
					# sometime in the past )
					if @subscription.failed?

						@subscription.status = 'active'
						@subscription.next_charged_at = Time.now if @subscription.next_charged_at < Time.now
						@subscription.save

					end
				end

			else

				@subscription.attributes = subscription_attributes
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
				{
					:shipping_address_attributes => [
						:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name,
					]
				},
			).to_h

			attributes.delete(:status) unless ['active','on_hold'].include?( attributes[:status] )
			attributes.delete(:next_charged_at) if attributes[:next_charged_at].blank?
			attributes[:next_charged_at] = "#{attributes[:next_charged_at]} 08:00:00 #{current_user.local_tz}" if attributes[:next_charged_at]
			attributes.delete(:billing_interval_unit) unless ['months','days','weeks'].include?( attributes[:billing_interval_unit] )

			attributes
		end

		def transaction_options
			params.slice( :stripeToken, :credit_card ).merge({ ip: client_ip, ip_country: client_ip_country })
		end

	end

end
