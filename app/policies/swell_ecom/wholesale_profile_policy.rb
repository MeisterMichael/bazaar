module SwellEcom
	class WholesaleProfilePolicy < ApplicationPolicy

		def admin?
			user.admin?
		end

		def admin_create?
			user.admin?
		end

		def admin_destroy?
			user.admin?
		end

		def admin_edit?
			user.admin?
		end

		def admin_show?
			user.admin?
		end

		def admin_update?
			user.admin?
		end
	end
end
