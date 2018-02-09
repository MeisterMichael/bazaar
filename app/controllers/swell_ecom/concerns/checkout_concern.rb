module SwellEcom::CheckoutConcern
	extend ActiveSupport::Concern

	def update_order_user_address( order )

		# if order user exists, update it's address info with the
		# billing address, if not already set
		if order.user.present?
			order.user.update(
				address1: (order.user.address1 || order.billing_address.street),
				address2: (order.user.address2 || order.billing_address.street2),
				city: (order.user.city || order.billing_address.city),
				state: (order.user.state || order.billing_address.state_abbrev),
				zip: (order.user.zip || order.billing_address.zip),
				phone: (order.user.phone || order.billing_address.phone)
			)
		end

	end

end
