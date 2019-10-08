
module Bazaar
	class Order < ApplicationRecord

		include Bazaar::Concerns::MoneyAttributesConcern
		include Bazaar::OrderSearchable if (Bazaar::OrderSearchable rescue nil)

		enum status: { 'trash' => -99, 'rejected' => -5, 'failed' => -1, 'draft' => 0, 'pre_order' => 1, 'active' => 2, 'review' => 98, 'archived' => 99, 'hold_review' => 110 }
		enum payment_status: { 'payment_failed' => -4, 'payment_canceled' => -3, 'declined' => -2, 'refunded' => -1, 'invoice' => 0, 'payment_method_captured' => 1, 'paid' => 2 }
		enum fulfillment_status: { 'fulfillment_canceled' => -3, 'fulfillment_error' => -1, 'unfulfilled' => 0, 'partially_fulfulled' => 1, 'fulfilled' => 2, 'delivered' => 3, 'return_to_sender' => 4 }
		enum generated_by: { 'customer_generated' => 1, 'system_generaged' => 2 }

		before_create :generate_order_code

		# belongs_to 	:billing_address, class_name: 'GeoAddress' # set in subsclass
		# belongs_to 	:shipping_address, class_name: 'GeoAddress' # set in subsclass
		belongs_to 	:user, required: false, class_name: 'User'
		belongs_to	:parent, polymorphic: true, required: false

		has_many 	:order_items, dependent: :destroy, validate: true
		has_many 	:order_offers, dependent: :destroy, validate: true
		has_many 	:order_skus, dependent: :destroy, validate: true
		has_many	:shipments
		has_many	:transactions, as: :parent_obj

		has_one 	:cart, dependent: :destroy

		validates_format_of	:email, with: Devise.email_regexp, if: :email_changed?
		validate :order_address_users_match

		money_attributes :subtotal, :tax, :shipping, :total, :discount


		# def email=(value)
		# 	super( Email.email_sanitize( value ) )
		# end

		def with_subscription?
			if self.persisted?
				self.order_offers.with_subscription.present?
			else
				self.order_offers.to_a.select(&:subscription).present?
			end
		end

		def with_recurring_offers?
			self.order_offers.to_a.collect(&:offer).select(&:recurring?).present?
		end

		def self.positive_status
			where('bazaar_orders.status > 0')
		end

		def self.negative_status
			where('bazaar_orders.status < 0')
		end

		def self.not_archived
			where.not( status: Bazaar::Order.statuses['archived'] )
		end

		def self.not_declined
			where.not( payment_status: Bazaar::Order.payment_statuses['declined'] )
		end

		def self.not_trash
			where.not( status: Bazaar::Order.statuses['trash'] )
		end

		def shipments_status_least
			( self.shipments.not_negative_status.order( status: :asc ).limit(1).first || self.shipments.order( status: :asc ).limit(1).first ).try(:status) || 'none'
		end

		def shipments_status_most
			( self.shipments.not_negative_status.order( status: :desc ).limit(1).first || self.shipments.order( status: :desc ).limit(1).first ).try(:status) || 'none'
		end

		def subscription_renewal?
			self.parent.is_a?( Bazaar::Subscription )
		end

		def nested_errors
			all_errors = self.errors.full_messages
			all_errors = all_errors.concat( self.billing_address.errors.full_messages ) if self.billing_address
			all_errors = all_errors.concat( self.shipping_address.errors.full_messages ) if self.shipping_address

			self.order_items.each do |order_item|
				all_errors = all_errors.concat( order_item.errors.full_messages )
			end

			all_errors
		end

		def to_s
			"Order #{self.code}"
		end

		private

		def order_address_users_match
			self.errors.add(:billing_address, "does not exist.") if self.user.present? && billing_address.present? && billing_address.user != self.user
			self.errors.add(:shipping_address, "does not exist.") if self.user.present? && shipping_address.present? && shipping_address.user != self.user
		end

		def generate_order_code
			self.code = loop do
  				token = SecureRandom.urlsafe_base64( 6 ).downcase.gsub(/_/,'-')
				token = "#{Bazaar.order_code_prefix}#{token}"if Bazaar.order_code_prefix.present?
				token = "#{token}#{Bazaar.order_code_postfix}"if Bazaar.order_code_postfix.present?
  				break token unless Order.exists?( code: token )
			end
		end

	end
end
