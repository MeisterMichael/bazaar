
class UserPolicy < SwellMedia::UserPolicy

	def customer_admin?
		user.admin?
	end

	def customer_admin_destroy?
		user.admin?
	end

	def customer_admin_edit?
		user.admin?
	end

	def customer_admin_update?
		user.admin?
	end

end
