SwellEcom::Engine.routes.draw do

	resources :carts, only: :update

	get '/cart' => 'carts#show'

	resources :cart_items

	resources :checkout, only: [:new, :create, :index] do
		post :confirm, on: :collection
		get :confirm, on: :collection
		get :state_input, on: :collection
		get :thank_you, on: :collection, path: 'thank-you'
	end

	resources :order_admin

	resources :orders, only: :show

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


end
