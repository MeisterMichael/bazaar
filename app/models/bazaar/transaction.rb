
module Bazaar
	class Transaction < ApplicationRecord

		include Bazaar::Concerns::MoneyAttributesConcern
		include Bazaar::TransactionSearchable if (Bazaar::TransactionSearchable rescue nil)

		enum transaction_type: { 'void' => -3, 'chargeback' => -2, 'refund' => -1, 'preauth' => 0, 'charge' => 1 }
		enum status: { 'declined' => -1, 'approved' => 1 }
		belongs_to :parent_obj, polymorphic: true, required: false # subscription, order
		belongs_to :billing_address, class_name: 'GeoAddress', required: false
		belongs_to :billing_user_address, class_name: 'UserAddress', required: false #, required: false

		money_attributes :amount, :signed_amount

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
