
module SwellEcom
	class Transaction < ActiveRecord::Base
		self.table_name = 'transactions'

		enum transaction_type: { 'chargeback' => -2, 'refund' => -1, 'preauth' => 0, 'charge' => 1 }
		enum status: { 'declined' => -1, 'approved' => 1 }
		belongs_to :parent_obj, polymorphic: true # subscription, order

		def self.debit
			where( 'transaction_type < 0' )
		end

		def self.credit
			where( 'transaction_type > 0' )
		end

	end
end
