module Bazaar
	class Warehouse < ApplicationRecord
		include Bazaar::Concerns::MoneyAttributesConcern

		has_many :warehouse_skus
		has_many :shipments

		enum status: { 'draft' => 0, 'active' => 100 }

		money_attributes :sku_cost, :sku_value
	end
end
