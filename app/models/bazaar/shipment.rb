module Bazaar
	class Shipment < ApplicationRecord
		include Bazaar::Concerns::UserAddressAttributesConcern
		include Bazaar::Concerns::MoneyAttributesConcern
		include Bazaar::ShipmentSearchable if (Bazaar::ShipmentSearchable rescue nil)

		attr_accessor :rates

		belongs_to	:user, required: false
		belongs_to	:order, required: false
		belongs_to	:destination_address, class_name: 'GeoAddress', validate: true, required: false
		belongs_to	:source_address, class_name: 'GeoAddress', required: false #, required: false
		belongs_to	:destination_user_address, class_name: 'UserAddress', required: false #, validate: true, required: false
		belongs_to	:source_user_address, class_name: 'UserAddress', required: false
		belongs_to	:warehouse, required: false
		belongs_to	:shipping_carrier_service, required: false

		has_many :shipment_logs
		has_many :shipment_skus
		has_many :skus, through: :shipment_skus

		enum status: { 'processing_error' => -900, 'rejected' => -100, 'canceled' => -1, 'draft' => 0, 'pending' => 10, 'processing' => 50, 'picking' => 100, 'packed' => 200, 'shipped' => 300, 'delivered' => 400, 'lost_in_transit' => 450, 'returned' => 500, 'review' => 900, 'hold_review' => 950 }
		# enum package_shape: { 'no_shape' => 0, 'letter' => 1, 'box' => 2, 'cylinder' => 3 }

		before_create :generate_shipment_code

		accepts_nested_attributes_for :shipment_skus, :destination_address

		validate :validate_warehouse_skus, if: :validate_warehouse_skus?

		money_attributes :cost, :price, :tax, :declared_value

		accepts_nested_user_address_attributes_for [:destination_user_address,:destination_address,:user_id]

		def clear_shipping_carrier_service
			self.shipping_carrier_service_id = nil
			self.cost = nil
			self.carrier = nil
			self.carrier_service_level = nil
			self.requested_service_level = nil
		end

		def clear_shipping_carrier_service!
			clear_shipping_carrier_service
			self.save
		end

		def not_negative_status?
			Bazaar::Shipment.statuses[self.status] >= 0
		end

		def self.not_negative_status
			where( status: 0..Float::INFINITY )
		end

		def not_shipped?
			Bazaar::Shipment.statuses[self.status] < Bazaar::Shipment.statuses['shipped']
		end

		def processable( args = {} )
			time = args[:time] || Time.now
			pending.where( processable_at: Time.at(0)..time )
		end

		def processable?( args = {} )
			time = args[:time] || Time.now
			pending? && processable_at <= time
		end

		def validate_warehouse_skus?
			self.warehouse.present? && self.warehouse_id_changed? && self.fulfillment_id.blank? && (self.pending? || self.draft?)
		end

		protected
		def generate_shipment_code
			self.code = loop do
				if Bazaar.shipment_code_generator_service_class.present?
					token = Bazaar.shipment_code_generator_service_class.constantize.generate_shipment_code( self )
				else
					token = SecureRandom.urlsafe_base64( 6 ).downcase.gsub(/_/,'-')
					token = "#{Bazaar.shipment_code_prefix}#{token}"if Bazaar.shipment_code_prefix.present?
					token = "#{token}#{Bazaar.shipment_code_postfix}"if Bazaar.shipment_code_postfix.present?
				end
				break token unless Shipment.exists?( code: token )
			end
		end

		def validate_warehouse_skus
			self.shipment_skus.each do |shipment_sku|
				warehouse_sku = shipment_sku.warehouse_sku

				unless warehouse_sku.present? && warehouse_sku.code.present?
					self.errors.add( :base, "Warehouse '#{self.try(:warehouse).try(:name)}' does not support the sku #{shipment_sku.sku.code}")
				end
			end
		end

	end
end
