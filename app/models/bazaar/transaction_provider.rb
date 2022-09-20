module Bazaar
	class TransactionProvider < ApplicationRecord
		self.table_name = 'bazaar_transaction_providers'

    belongs_to	:merchant_identification, class_name: 'Bazaar::MerchantIdentification', required: false
    belongs_to	:transaction_provider_interface, class_name: 'Bazaar::TransactionProviderInterface'

	end
end
