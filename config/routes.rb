SwellEcom::Engine.routes.draw do

	resources :cart_admin
	resources :carts, only: :update

	get '/cart' => 'carts#show'

	resources :cart_items, except: [ :index, :new, :edit, :update, :show ] do
		get :create, on: :collection
	end

	resources :checkout_admin, only: [:create, :index] do
		post :confirm, on: :collection
		get :confirm, on: :collection
		get :state_input, on: :collection
	end

	resources :checkout, only: [:new, :create, :index] do
		post :confirm, on: :collection
		get :confirm, on: :collection
		get :state_input, on: :collection
	end

	resources :customer_admin
	resources :discount_admin

	resources :order_admin do
		post :refund, on: :member
		post :address, on: :member
		patch :bulk_update, on: :collection, path: ''
		put :bulk_update, on: :collection, path: ''
	end

	resources :orders do
		get :thank_you, on: :member, path: 'thank-you'
	end

	resources :products, path: :store do
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

	resources :subscription_admin do
		post :cancel, on: :member
		post :address, on: :member
		post :payment_profile, on: :member
	end
	resources :subscription_plan_admin

	resources :subscription_plans, path: 'subscriptions'

	resources :your_account, only: [:index]
	resources :your_orders, only: [:index, :show]
	resources :your_subscriptions, only: [:index, :show, :update, :destroy]

	resources :zendesk, only: [:index] do
		get :customer, on: :collection
	end


end
