module SwellEcom

	class YourSubscriptionsController < YourController

		before_filter :get_subscription, except: [ :index ]

		def index
			set_page_meta( title: "My Subscriptions" )
			@subscriptions = SwellEcom::Subscription.where( user: current_user ).order( next_charged_at: :desc ).page(params[:page]).per(5)
		end

		def show
			@orders = @subscription.orders.order( created_at: :desc ).page(params[:page]).per(5)
			set_page_meta( title: "Subscription Details \##{@subscription.code} " )


			@billing_countries 	= SwellEcom::GeoCountry.all
			@shipping_countries = SwellEcom::GeoCountry.all

			@billing_countries = @billing_countries.where( abbrev: SwellEcom.billing_countries[:only] ) if SwellEcom.billing_countries[:only].present?
			@billing_countries = @billing_countries.where( abbrev: SwellEcom.billing_countries[:except] ) if SwellEcom.billing_countries[:except].present?

			@shipping_countries = @shipping_countries.where( abbrev: SwellEcom.shipping_countries[:only] ) if SwellEcom.shipping_countries[:only].present?
			@shipping_countries = @shipping_countries.where( abbrev: SwellEcom.shipping_countries[:except] ) if SwellEcom.shipping_countries[:except].present?

			@billing_states 	= SwellEcom::GeoState.where( geo_country_id: @subscription.shipping_address.try(:geo_country_id) || @billing_countries.first.id ) if @billing_countries.count == 1
			@shipping_states	= SwellEcom::GeoState.where( geo_country_id: @subscription.billing_address.try(:geo_country_id) || @shipping_countries.first.id ) if @shipping_countries.count == 1

		end

		def update

			if ( payment_info = params[:payment_info] ).present?


				if payment_info[:billing_address_attributes].present?

					billing_address_attributes = payment_info.require(:billing_address_attributes).permit( :first_name, :last_name, :geo_country_id, :geo_state_id, :street, :street2, :city, :zip, :phone )
					billing_address = GeoAddress.create( billing_address_attributes.merge( user: current_user ) )

					if billing_address.errors.present?
						set_flash billing_address.errors.full_messages, :danger
						redirect_to :back
						return false
					end

					@subscription.update( billing_address: billing_address )

				end

				@transaction_service = SwellEcom.transaction_service_class.constantize.new( SwellEcom.transaction_service_config )
				
				if @transaction_service.update_subscription_payment_profile( @subscription, params )

					# if subscription was failed, set the status to active and
					# next charge date to now ( if it was set to be charged
					# sometime in the past )
					if @subscription.failed?

						@subscription.status = 'active'
						@subscription.next_charged_at = Time.now if @subscription.next_charged_at < Time.now
						@subscription.save

					end
				end

			end

			if @subscription.errors.present?
				set_flash @subscription.errors.full_messages, :danger
			else
				set_flash "Subscription updated succesfully.", :success
			end

			redirect_to :back

		end

		private

		def get_subscription
			@subscription = SwellEcom::Subscription.where( user: current_user ).find_by( code: params[:id] )
			raise ActionController::RoutingError.new( 'Not Found' ) unless @subscription.present?
		end

	end

end
