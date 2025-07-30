module Bazaar
	class OrderAdminController < Bazaar::EcomAdminController
		include Bazaar::Concerns::CheckoutConcern
		helper_method :shipping_options
		helper_method :transaction_options

		before_action :initialize_services, only: [ :edit ]


		before_action :get_order, except: [ :index, :create, :new ]
		before_action :initialize_search_service, only: [ :index ]
		before_action :initialize_fraud_service, only: [ :accept, :reject, :hold ]

		def accept

			if @fraud_service.accept_review( @order )

				set_flash "Order has been activated.", :success
				log_event( name: 'accept', on: @order, content: "accepted order #{@order.code}", category: 'ecom' )

			end

			redirect_back fallback_location: '/admin'

		end

		def address
			authorize( @order )
			address_attributes = params.require( :user_address ).permit( :first_name, :last_name, :geo_country_id, :geo_state_id, :state, :street, :street2, :city, :zip, :phone )
			address = UserAddress.canonical_find_or_create_with_cannonical_geo_address( address_attributes.merge( user: @order.user ) )

			if address.errors.present?

				set_flash address.errors.full_messages, :danger

			else

				user_address_attribute_name = params[:attribute] == 'billing_user_address' ? 'billing_user_address' : 'shipping_user_address'
				geo_address_attribute_name = user_address_attribute_name.gsub(/user_/,'')

				# @todo trash the old address if it's no long used by any orders or subscriptions
				@order.update(
					user_address_attribute_name => address,
					geo_address_attribute_name => address.geo_address
				)

				if @order.errors.present?
					set_flash address.errors.full_messages, :danger
				else
					set_flash "Address Updated", :success
				end

			end
			redirect_back fallback_location: '/admin'
		end


		def edit
			unless @order.draft?
				redirect_to order_admin_path( @order )
				return
			end

			authorize( @order )

			@order.options = {
				transaction: transaction_options,
				shipping: shipping_options,
				discount: discount_options,
			}

			@order_service.calculate( @order, @order.options )

			set_page_meta( title: "#{@order.code} | Order" )
		end


		def hold

			if @fraud_service.hold_for_review( @order )

				set_flash "Order has been held for review.", :success
				log_event( name: 'hold_review', on: @order, content: "order held for review #{@order.code}", category: 'ecom', user: @order.user )
				Bazaar::OrderMailer.hold_for_review(@order).deliver_now
			end

			redirect_back fallback_location: '/admin'

		end


		def index
			authorize( Bazaar::Order )
			sort_by = params[:sort_by] || 'created_at'
			sort_dir = params[:sort_dir] || 'desc'

			@search_mode = params[:search_mode] || 'elastic'

			filters = ( params[:filters] || {} ).select{ |attribute,value| not( value.nil? ) }
			filters[:renewal] = @renewal_filter = params[:renewal]
			filters[:type] = @type_filter = ( params[:type] || 'Bazaar::CheckoutOrder' )
			filters[:not_trash] = true if params[:q].blank? # don't show trash, unless searching
			filters[:not_archived] = true if params[:q].blank? # don't show archived, unless searching
			filters[ params[:status] ] = true if params[:status].present? && params[:status] != 'all'
			filters[ params[:payment_status] ] = true if params[:payment_status].present? && params[:payment_status] != 'all'
			@orders = @search_service.order_search( params[:q], filters, page: params[:page], order: { sort_by => sort_dir }, mode: @search_mode )

			set_page_meta( title: "Orders" )
		end

		def refund
			authorize( @order )
			refund_amount = ( params[:amount].to_f * 100 ).round

			# check that refund amount doesn't exceed charges?
			# amount_net = Transaction.approved.positive.where( parent: @order ).sum(:amount) - Transaction.approved.negative.where( parent: @order ).sum(:amount)

			@order_service = Bazaar.checkout_order_service_class.constantize.new

			@transactions = @order_service.refund( amount: refund_amount, order: @order )
			@transactions = [@transactions] if @transactions.is_a? Bazaar::Transaction

			if ( transaction_errors = @transactions.collect{|transaction| transaction.errors.full_messages }.select(&:present?).join('. ') ).present?

				set_flash transaction_errors, :danger

			elsif ( declined_messages = @transactions.select(&:declined?).collect(&:message).select(&:present?).join('. ') ).present?

				set_flash declined_messages, :danger

			else

				@order.refunded!

				@order.shipments.update_all( status: 'canceled' ) if params[:cancel_fullfillment]

				@transactions.select(&:approved?).select(&:negative?).each do |transaction|
					Bazaar::OrderMailer.refund( transaction ).deliver_now
				end
				set_flash "Refund successful", :success

				log_event( user: @order.user, name: 'refund', value: -@transactions.sum(&:amount), on: @order, content: "refunded #{@transactions.sum(&:amount_as_money)} on order #{@order.code}" )

			end

			redirect_to bazaar.order_admin_path( @order )
		end

		def reject

			if @fraud_service.reject_review( @order )

				set_flash "Order has been rejected.", :success

			end

			redirect_back fallback_location: '/admin'

		end

		def show
			# if @order.draft?
			# 	redirect_to edit_order_admin_path( @order )
			# 	return
			# end

			authorize( @order )

			@transactions = Transaction.where( parent_obj: @order )

			@transaction_history = @transactions.to_a
			@transaction_history = @transaction_history + Transaction.where( parent_obj: @order.cart ) if @order.cart
			@transaction_history = @transaction_history + Transaction.where( parent_obj: @order.user, created_at: 1.week.ago..@order.created_at ) if @order.user
			@transaction_history = @transaction_history.sort_by(&:created_at).reverse

			@shipments = @order.shipments.order( created_at: :desc )

			@fraud_events = Bunyan::Event.where( target_obj: @order, name: 'fraud_warning' ).order( created_at: :desc )

			set_page_meta( title: "#{@order.code} | Order" )
		end

		def thank_you
			@order = Order.find_by( code: params[:id] )

			render 'bazaar/orders/thank_you'
		end

		def timeline
			authorize( @order )

			@transactions = Bazaar::Transaction.where( parent_obj: @order )

			@events = Bunyan::Event.where( target_obj: @order )
			@events = @events.or( Bunyan::Event.where.not( user_id: nil ).where( user_id: @order.user_id, created_at: Time.at(0)..(@order.created_at + 10.minutes) ) )
			@events = @events.or( Bunyan::Event.where( target_obj: @transactions ) )
			@events = @events.where( category: [ 'account', 'ecom' ] )
			@events = @events.order( created_at: :desc ).page( params[:page] )

			set_page_meta( title: "Order Timeline" )

		end


		def update
			authorize( @order )
			@order.attributes = order_params

			@order.save

			@order.order_offers.where( quantity: 0 ).destroy_all

			respond_to do |format|
				format.js {
					render :update
				}
				format.json {
					render :update
				}
				format.html {
					set_flash "Order Updated", :success
					redirect_back fallback_location: '/admin'
				}
			end
		end

		private
			def order_params
				order_attributes = params.require( :order ).permit(
					:email,
					:ip,
					:currency,
					:status,
					:payment_status,
					:support_notes,
					:customer_notes,
					:same_as_billing,
					:same_as_shipping,
					:returned,
					{
						:billing_user_address_attributes => [
							:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name,
						],
						:shipping_user_address_attributes => [
							:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name,
						],
						:order_offers_attributes => [
							:offer_id,
							:quantity,
							:price,
							:price_as_money,
							:price_as_money_string,
							:subtotal,
							:subtotal_as_money,
							:subtotal_as_money_string,
							:title,
							:tax_code,
						],
					}
				).to_h

				if order_attributes[:order_offers_attributes]
					order_attributes[:order_offers_attributes] = order_attributes[:order_offers_attributes].select{|index, order_offer_attributes| order_offer_attributes[:quantity].present? }
				end

				if order_attributes[:same_as_shipping] == '1' && order_attributes[:shipping_user_address_attributes].present?
					order_attributes.delete(:same_as_shipping)
					order_attributes[:billing_user_address_attributes] = order_attributes[:shipping_user_address_attributes]
				end

				if order_attributes[:same_as_billing] == '1' && order_attributes[:billing_user_address_attributes].present?
					order_attributes.delete(:same_as_billing)
					order_attributes[:shipping_user_address_attributes] = order_attributes[:billing_user_address_attributes]
				end

				order_attributes
			end

			def get_order
				@order = Order.find_by( id: params[:id] )
			end

			def initialize_fraud_service
				@fraud_service = Bazaar.fraud_service_class.constantize.new( Bazaar.fraud_service_config )
			end

			def initialize_search_service
				@search_service = Bazaar.search_service_class.constantize.new( Bazaar.search_service_config )
			end

	end
end
