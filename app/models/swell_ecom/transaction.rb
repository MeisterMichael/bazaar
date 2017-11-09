
module SwellEcom
	class Transaction < ActiveRecord::Base
		self.table_name = 'transactions'

		enum transaction_type: { 'void' => -3, 'chargeback' => -2, 'refund' => -1, 'preauth' => 0, 'charge' => 1 }
		enum status: { 'declined' => -1, 'approved' => 1 }
		belongs_to :parent_obj, polymorphic: true # subscription, order

		def negative?
			void? || chargeback? || refund?
		end

		def positive?
			charge?
		end

		def signed_amount
			if negative?
				-amount
			else
				amount
			end
		end

		def self.negative
			where( 'transaction_type < 0' )
		end

		def self.positive
			where( 'transaction_type > 0' )
		end

	end
end
