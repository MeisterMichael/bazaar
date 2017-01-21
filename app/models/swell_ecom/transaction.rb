
module SwellEcom
	class Transaction < ActiveRecord::Base
		self.table_name = 'transactions'

		enum transaction_type: { 'chargeback' => -2, 'refund' => -1, 'preauth' => 0, 'charge' => 1 }
		enum status: { 'declined' => -1, 'approved' => 1 }
		belongs_to :parent, polymorphic: true # subscription, order

	end
end
