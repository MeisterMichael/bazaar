module Bazaar
	class Shipment < ApplicationRecord
		include Bazaar::Concerns::MoneyAttributesConcern

		belongs_to	:order, required: false
		belongs_to	:destination_address, required: false
		belongs_to	:source_address, required: false
		belongs_to	:warehouse, required: false

		has_many :shipment_logs
		has_many :shipment_skus

		enum status: { 'pending' => 0, 'picking' => 100, 'packed' => 200, 'shipped' => 300, 'delivered' => 400, 'returned' => 500 }

		money_attributes :cost


	end
end
