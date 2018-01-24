if @user.present?
	json.status 200
	json.first_name @user.first_name
	json.last_name @user.last_name
	json.email @user.email
	json.url swell_ecom.edit_customer_admin_url( @user )
	json.orders_count @orders.count
	json.orders_total @orders.sum(:total) / 100.0
	json.orders(@orders) do |order|
	  json.code order.code
	  json.created_at order.created_at.strftime('%Y-%m-%dT%H:%M:%SZ')
	  json.fulfilled_at order.fulfilled_at.try( :strftime, '%Y-%m-%dT%H:%M:%SZ' )
	  json.url swell_ecom.edit_order_admin_url( order )
	  json.total order.total / 100.0
	end
else
	json.status 404
end
