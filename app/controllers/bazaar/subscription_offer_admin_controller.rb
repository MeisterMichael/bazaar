module Bazaar
	class SubscriptionOfferAdminController < Bazaar::EcomAdminController

		before_action :get_subscription_offer, except: [ :index, :create ]

		def create
			authorize( Bazaar::SubscriptionOffer )

			@subscription = Bazaar::Subscription.find subscription_offer_params[:subscription_id]
			@offer = Bazaar::Offer.find subscription_offer_params[:offer_id]


			@subscription_service = Bazaar.subscription_service_class.constantize.new( Bazaar.subscription_service_config )
			@subscription_offer = @subscription_service.subscribe_subscription_offer(
				@subscription,
				@offer,
				{
					quantity: subscription_offer_params[:quantity],
					next_subscription_interval: subscription_offer_params[:next_subscription_interval],
				}
			)

			if @subscription_offer.errors.present?
				set_flash 'Subscription Offer could not be added', :error, @subscription_offer
			else
				set_flash 'Subscription Offer added'
			end

			redirect_back fallback_location: edit_subscription_admin_path( @subscription )
		end

		def destroy
			authorize( @subscription_offer )
			subscription = @subscription_offer.subscription

			@subscription_offer.status = 'trash'
			@subscription_offer.canceled_at = Time.now

			if @subscription_offer.save

				@subscription_service = Bazaar.subscription_service_class.constantize.new( Bazaar.subscription_service_config )
				@subscription_service.subscription_recalculate( subscription )
				subscription.save!

				set_flash "Subscription Offer deleted successfully", :success
			else
				set_flash @subscription_offer.errors.full_messages, :danger
			end

			redirect_back fallback_location: edit_subscription_admin_path( subscription )
		end

		def update
			authorize( @subscription_offer )

			subscription_options = subscription_offer_params
			offer_id = subscription_options.delete(:offer_id)

			if offer_id.present?
				offer = Bazaar::Offer.find(offer_id)
			else
				offer = @subscription_offer.offer
			end

			@subscription_service = Bazaar.subscription_service_class.constantize.new( Bazaar.subscription_service_config )
			@subscription_service.subscription_offer_change_offer( @subscription_offer, offer, subscription_options )

			if @subscription_offer.errors.blank?
				set_flash "Subscription Offer updated successfully", :success

			else

				set_flash @subscription_offer.errors.full_messages, :danger

			end

			if params[:redirect_to] == 'edit'
				redirect_to edit_subscription_admin_path( @subscription_offer.subscription )
			else
				redirect_back fallback_location: '/admin'
			end
		end

		private
			def subscription_offer_params
				params.require( :subscription_offer ).permit( :subscription_id, :offer_id, :quantity, :next_subscription_interval )
			end

			def get_subscription_offer
				@subscription_offer = SubscriptionOffer.find_by( id: params[:id] )
			end

	end
end
