SwellEcom::Engine.routes.draw do

	resources :cart
	resources :cart_items

	resources :checkout

	resources :products, path: :store

	resources :order_admin

	resources :product_admin do 
		get :preview, on: :member
		delete :empty_trash, on: :collection 
	end
	
	resources :refund_admin
	resources :transaction_admin

end
