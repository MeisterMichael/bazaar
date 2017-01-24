SwellEcom::Engine.routes.draw do

	resources :checkout, only: [:new, :create] do
		post :confirm, on: :collection
		get :state_input, on: :collection
	end

	resources :orders, only: :show

	resources :products, path: :store do
		# for single-item quick buy
		get :buy, on: :member
	end

	resources :order_admin

	resources :product_admin do
		get :preview, on: :member
		delete :empty_trash, on: :collection
	end

end
