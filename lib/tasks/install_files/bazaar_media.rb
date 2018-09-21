
class BazaarMedia < ApplicationRecord
	include Bazaar::Concerns::MediaConcern

	mounted_at '/bazaar'

end
