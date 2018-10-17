
module Bazaar
	class Order < ApplicationRecord
		
		include Bazaar::Concerns::MoneyAttributesConcern

		enum status: { 'trash' => -99, 'rejected' => -5, 'draft' => 0, 'pre_order' => 1, 'active' => 2, 'review' => 98, 'archived' => 99, 'hold_review' => 110 }
		enum payment_status: { 'payment_canceled' => -3, 'declined' => -2, 'refunded' => -1, 'invoice' => 0, 'payment_method_captured' => 1, 'paid' => 2 }
		enum fulfillment_status: { 'fulfillment_canceled' => -3, 'fulfillment_error' => -1, 'unfulfilled' => 0, 'partially_fulfulled' => 1, 'fulfilled' => 2, 'delivered' => 3, 'return_to_sender' => 4 }
		enum generated_by: { 'customer_generated' => 1, 'system_generaged' => 2 }

		before_create :generate_order_code

		belongs_to 	:billing_address, class_name: 'GeoAddress', validate: true, required: true
		belongs_to 	:shipping_address, class_name: 'GeoAddress', validate: true, required: true
		belongs_to 	:user, required: false, class_name: 'User'
		belongs_to	:parent, polymorphic: true, required: false

		has_many 	:order_items, dependent: :destroy, validate: true
		has_many	:transactions, as: :parent_obj

		has_one 	:cart, dependent: :destroy

		validates_format_of	:email, with: Devise.email_regexp, if: :email_changed?
		validate :order_address_users_match

		accepts_nested_attributes_for :billing_address, :shipping_address, :order_items

		money_attributes :subtotal, :tax, :shipping, :total, :discount


		# def email=(value)
		# 	super( Email.email_sanitize( value ) )
		# end

		def self.not_archived
			where.not( status: Bazaar::Order.statuses['archived'] )
		end

		def self.not_declined
			where.not( payment_status: Bazaar::Order.payment_statuses['declined'] )
		end

		def self.not_trash
			where.not( status: Bazaar::Order.statuses['trash'] )
		end

		def subscription_renewal?
			self.parent.is_a?( Bazaar::Subscription )
		end

		def has_subscription_plan?
			self.order_items.select{ |order_item| order_item.item.is_a?( Bazaar::SubscriptionPlan ) }.present?
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
			self.errors.add(:billing_address, "does not exist.") if self.user.present? && billing_address.user != self.user
			self.errors.add(:shipping_address, "does not exist.") if self.user.present? && shipping_address.user != self.user
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
