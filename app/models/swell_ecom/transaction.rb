
module SwellEcom
	class Transaction < ApplicationRecord
		self.table_name = 'transactions'

		include SwellEcom::Concerns::MoneyAttributesConcern

		enum transaction_type: { 'void' => -3, 'chargeback' => -2, 'refund' => -1, 'preauth' => 0, 'charge' => 1 }
		enum status: { 'declined' => -1, 'approved' => 1 }
		belongs_to :parent_obj, polymorphic: true, required: false # subscription, order
		belongs_to :billing_address, required: false, class_name: 'GeoAddress'

		money_attributes :amount

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

		def to_s
			"#{slf.reference_code}: #{self.transaction_type} #{self.status} #{self.provider} #{self.amount.to_f / 100}"

		end

		def self.negative
			where( 'transaction_type < 0' )
		end

		def self.positive
			where( 'transaction_type > 0' )
		end

	end
end
