BazaarWeb::Engine.routes.draw do

	resources :carts, only: :update

	get '/cart' => 'carts#show'

	resources :cart_offers, :path => "cart_offers", except: [ :index, :new, :edit, :update, :show ] do
		get :create, on: :collection
	end
	resources :cart_offers, :path => "cart_items", except: [ :index, :new, :edit, :update, :show ] do
		get :create, on: :collection
	end

	resources :checkout, only: [:new, :create, :index] do
		post :calculate, on: :collection
		post :confirm, on: :collection
		get :confirm, on: :collection
		get :state_input, on: :collection
	end

	# resources :geo_countries, only: [:index]
	resources :geo_states, only: [:index]

	resources :orders do
		get :thank_you, on: :member, path: 'thank-you'
	end

	resources :wholesale_checkout, only: [:create,:index] do
		post :calculate, on: :collection
		post :confirm, on: :collection
		get :thank_you, on: :member, path: 'thank-you'
	end

	resources :your_account, only: [:index]
	resources :your_orders, only: [:index, :show]
	resources :your_subscriptions, only: [:index, :show, :update, :destroy] do
		put :update_discount, on: :member
		get :edit_shipping_preferences, on: :member
	end

end
