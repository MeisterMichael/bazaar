# config/routes.rb
# + resources :amazon_pay_checkout, only: [:new, :create] do
# +   get :create, on: :collection
# + end

class AmazonPayCheckoutController < BazaarCore::CheckoutController

  before_action :initialize_services, only: [ :create, :new ]
  before_action :get_amazon_pay_service, only: [ :create, :new ]

  def create
    # validate that the signature is correct
    if Digest::SHA256.base64digest( @cart.checkout_cache.to_json ) != params[:cart_signature]

      set_flash "Your cart has changed since you checked out, please try again.", :danger
      redirect_to '/checkout'

    elsif ( @amz.validate_pay_signature( URI.unescape(params[:signature]), result_parameters.to_h, algorithm: params[:algorithm], path: amazon_pay_checkout_index_path(), method: 'GET', host: Pulitzer.app_host ) )

      super()

    else

      set_flash "Invalid response from amazon.", :danger
      redirect_to '/checkout'

    end
  end

  def new

    data = params.permit(:amount,:currencyCode).to_h
    data[:returnURL]                = amazon_pay_checkout_index_url( cart_signature: Digest::SHA256.base64digest( @cart.checkout_cache.to_json ) )
    data[:shippingAddressRequired]  = 'false'
    data[:paymentAction]            = 'None'
    data = @amz.sign_pay_parameters( data )

    render json: data, layout: false
  end

  protected

  def result_parameters
    params.permit(
      :resultCode,
      :sellerId,
      :sellerOrderId,
      :SignatureMethod,
      :SignatureVersion,
      :AWSAccessKeyId,
      :orderReferenceId,
      :amount,
      :currencyCode,
      :paymentAction
    )
  end

	def get_order_attributes
    attributes = super()
    attributes = attributes.merge(@cart.checkout_cache['order_attributes'].deep_symbolize_keys)
    attributes
	end

	def get_order
		@order = Bazaar::CheckoutOrder.new( get_order_attributes )
		@order.billing_address.user = @order.shipping_address.user = @order.user

		discount = Bazaar::Discount.active.in_progress.where( 'lower(code) = ?', discount_options[:code].downcase ).first if discount_options[:code].present?
		order_item = @order.order_items.new( item: discount, order_item_type: 'discount', title: discount.title ) if discount.present?

	end

  def transaction_options
    super().merge(result_parameters).merge( service: 'amazon_pay' )
  end

  def shipping_options
    @cart.checkout_cache['shipping_options'].deep_symbolize_keys
  end

  def discount_options
    @cart.checkout_cache['discount_options'].deep_symbolize_keys
  end

  def get_amazon_pay_service
    @amz = @order_service.transaction_service.find_transaction_service_by_name( 'Amazon Pay' ) || BazaarCore::TransactionServices::AmazonPayTransactionService.new
  end

end
