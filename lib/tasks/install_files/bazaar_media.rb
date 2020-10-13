
class BazaarMedia < ApplicationRecord
	include Bazaar::Concerns::MediaConcern
	include BazaarMediaSearchable if (BazaarMediaSearchable rescue nil)

	mounted_at '/bazaar_core'

end
