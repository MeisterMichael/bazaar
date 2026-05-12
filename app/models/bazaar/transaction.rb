
module Bazaar
	class Transaction < ApplicationRecord

		include Bazaar::Concerns::MoneyAttributesConcern
		include Bazaar::TransactionSearchable if (Bazaar::TransactionSearchable rescue nil)

		enum transaction_type: { 'void' => -3, 'chargeback' => -2, 'refund' => -1, 'preauth' => 0, 'charge' => 1 }
		enum status: { 'declined' => -1, 'approved' => 1 }
		belongs_to :parent_obj, polymorphic: true, required: false # subscription, order
		belongs_to :order, class_name: 'Bazaar::Order', optional: true
		belongs_to :billing_address, class_name: 'GeoAddress', required: false
		belongs_to :billing_user_address, class_name: 'UserAddress', required: false #, required: false
		belongs_to	:transaction_provider, required: false
		belongs_to	:merchant_identification, required: false

		money_attributes :amount, :signed_amount

		before_save :derive_order_id_from_parent_obj

		def derive_order_id_from_parent_obj
			# Auto-populate order_id when parent_obj is an Order so transactions are
			# always joinable to their order. Failed-renewal transactions whose
			# parent_obj is a Subscription must set order_id explicitly.
			return if order_id.present?
			return unless parent_obj_type.present? && parent_obj_id.present?
			return unless parent_obj_type == 'Bazaar::Order' || parent_obj_type.constantize <= Bazaar::Order
			self.order_id = parent_obj_id
		rescue NameError
			nil
		end

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
			"#{self.reference_code}: #{self.transaction_type} #{self.status} #{self.provider} #{self.amount.to_f / 100}"

		end

		def self.negative
			where( 'transaction_type < 0' )
		end

		def self.positive
			where( 'transaction_type > 0' )
		end

	end
end
