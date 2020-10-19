Bazaar::Engine.routes.draw do

	resources :cart_admin

	resources :collection_admin
	resources :collection_item_admin

	resources :discount_admin

	resources :fulfillment_admin, only: [:create, :destroy]

	resources :offer_admin
	resources :offer_price_admin
	resources :offer_schedule_admin
	resources :offer_sku_admin

	resources :order_admin do
		post :accept, on: :member
		post :address, on: :member
		post :hold, on: :member
		post :refund, on: :member
		post :reject, on: :member
		get :thank_you, on: :member
		get :timeline, on: :member
		put :update_discount, on: :member
	end

	resources :order_item_admin, only: [:update,:create,:destroy]
	resources :order_offer_admin, only: [:update,:create,:destroy]

	resources :product_admin do
		get :preview, on: :member
		delete :empty_trash, on: :collection
	end

	resources :shipment_admin do
		post :batch_create, on: :collection
		get :batch_template, on: :collection
		put :batch_update, on: :collection
	end

	resources :shipping_carrier_service_admin, only: [:index,:edit,:update]
	resources :shipping_option_admin, only: [:index,:edit,:update,:create]

	resources :shipment_admin do
		get :edit_destination, on: :member
		get :edit_items, on: :member
		get :edit_shape, on: :member
		get :edit_service, on: :member
	end
	resources :shipment_sku_admin

	resources :sku_admin
	resources :sku_country_admin

	resources :subscription_admin do
		post :cancel, on: :member
		post :address, on: :member
		post :payment_profile, on: :member
		get :edit_shipping_carrier_service, on: :member
		get :timeline, on: :member
		patch :update_offer, on: :member
	end

	resources :transaction_admin

	resources :upsell_offer_admin, only: [:create,:update,:destroy]

	resources :warehouse_admin
	resources :warehouse_country_admin
	resources :warehouse_state_admin
	resources :warehouse_sku_admin

	resources :wholesale_item_admin, only: [:create,:update,:destroy]
	resources :wholesale_profile_admin, except: [:new]

	resources :zendesk, only: [:index] do
		get :customer, on: :collection
	end


end
