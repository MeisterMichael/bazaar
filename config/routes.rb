Bazaar::Engine.routes.draw do

	resources :cart_admin
	resources :carts, only: :update

	get '/cart' => 'carts#show'

	resources :cart_items, except: [ :index, :new, :edit, :update, :show ] do
		get :create, on: :collection
	end

	resources :checkout_admin, only: [:create, :index, :update] do
		post :confirm, on: :collection
		get :confirm, on: :collection
		get :state_input, on: :collection
	end

	resources :checkout, only: [:new, :create, :index] do
		post :calculate, on: :collection
		post :confirm, on: :collection
		get :confirm, on: :collection
		get :state_input, on: :collection
	end

	resources :discount_admin

	resources :fulfillment_order_admin, only: [:create, :new]

	resources :fulfillment_admin, only: [:create, :destroy]

	# resources :geo_countries, only: [:index]
	resources :geo_states, only: [:index]

	resources :offer_sku_admin

	resources :order_admin do
		post :accept, on: :member
		post :address, on: :member
		post :hold, on: :member
		post :refund, on: :member
		post :reject, on: :member
		get :thank_you, on: :member
		put :update_discount, on: :member
	end

	resources :order_item_admin, only: [:update,:create,:destroy]

	resources :orders do
		get :thank_you, on: :member, path: 'thank-you'
	end

	resources :products, path: Bazaar.store_path do
		# for single-item quick buy
		get :buy, on: :member
	end

	resources :product_admin do
		get :preview, on: :member
		delete :empty_trash, on: :collection
	end

	resources :product_options

	resources :product_variants do
		post :generate, on: :member
	end

	resources :shipping_carrier_service_admin, only: [:index,:edit,:update]
	resources :shipping_option_admin, only: [:index,:edit,:update,:create]

	resources :shipment_admin
	resources :shipment_sku_admin

	resources :sku_admin
	resources :sku_country_admin

	resources :subscription_admin do
		post :cancel, on: :member
		post :address, on: :member
		post :payment_profile, on: :member
		get :edit_shipping_carrier_service, on: :member
	end
	resources :subscription_plan_admin

	resources :subscription_plans, path: 'subscriptions'

	resources :warehouse_admin
	resources :warehouse_country_admin
	resources :warehouse_sku_admin

	resources :wholesale_checkout, only: [:create,:index] do
		post :calculate, on: :collection
		post :confirm, on: :collection
		get :thank_you, on: :member, path: 'thank-you'
	end

	resources :wholesale_item_admin, only: [:create,:update,:destroy]
	resources :wholesale_profile_admin, except: [:new]

	resources :your_account, only: [:index]
	resources :your_orders, only: [:index, :show]
	resources :your_subscriptions, only: [:index, :show, :update, :destroy] do
		put :update_discount, on: :member
		get :edit_shipping_preferences, on: :member
	end

	resources :zendesk, only: [:index] do
		get :customer, on: :collection
	end


end
