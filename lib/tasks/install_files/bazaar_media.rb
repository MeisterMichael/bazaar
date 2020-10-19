
class BazaarMedia < ApplicationRecord
	include BazaarCore::Concerns::MediaConcern
	include BazaarMediaSearchable if (BazaarMediaSearchable rescue nil)

	mounted_at '/bazaar'

end
