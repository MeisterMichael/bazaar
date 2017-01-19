SwellEcom::Engine.routes.draw do

	resources :cart
	resources :cart_items

	resources :checkout do 	
		get :success, on: :collection
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

	resources :refund_admin
	resources :transaction_admin

end
