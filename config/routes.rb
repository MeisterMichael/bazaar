SwellEcom::Engine.routes.draw do

	resources :cart_admin
	resources :carts, only: :update

	get '/cart' => 'carts#show'

	resources :cart_items, except: [ :index, :new, :edit, :update, :show ] do
		get :create, on: :collection
	end

	resources :checkout, only: [:new, :create, :index] do
		post :confirm, on: :collection
		get :confirm, on: :collection
		get :state_input, on: :collection
	end

	resources :customer_admin

	resources :order_admin do
		post :refund, on: :member
		post :address, on: :member
	end

	resources :orders do
		get :thank_you, on: :member, path: 'thank-you'
	end

	resources :my, only: [:index], path: 'me'
	resources :my_account, only: [:index] do
		put :update, on: :collection, path: ''
	end
	resources :my_orders, only: [:index, :show]
	resources :my_subscriptions, only: [:index, :show]

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

	resources :subscription_plans
	resources :subscriptions do
		post :cancel, on: :member
	end


end
