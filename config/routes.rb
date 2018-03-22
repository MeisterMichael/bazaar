SwellEcom::Engine.routes.draw do

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

	resources :customer_admin
	resources :discount_admin

	# resources :geo_countries, only: [:index]
	resources :geo_states, only: [:index]

	resources :order_admin do
		post :refund, on: :member
		post :address, on: :member
		patch :bulk_update, on: :collection, path: ''
		put :bulk_update, on: :collection, path: ''
		get :thank_you, on: :member
	end

	resources :orders do
		get :thank_you, on: :member, path: 'thank-you'
	end

	resources :products, path: SwellEcom.store_path do
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

	resources :subscription_admin do
		post :cancel, on: :member
		post :address, on: :member
		post :payment_profile, on: :member
	end
	resources :subscription_plan_admin

	resources :subscription_plans, path: 'subscriptions'

	resources :your_account, only: [:index]
	resources :your_orders, only: [:index, :show]
	resources :your_subscriptions, only: [:index, :show, :update, :destroy] do
		put :update_discount, on: :member
	end

	resources :zendesk, only: [:index] do
		get :customer, on: :collection
	end


end
