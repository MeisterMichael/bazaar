SwellEcom::Engine.routes.draw do

	resources :store, controller: :products

	resources :cart_items

	resources :order_admin
	resources :refund_admin
	resources :transaction_admin

	get '/cart', to: 'carts#show', as: :cart
	post '/checkout', to: 'orders#new', as: :checkout


end
