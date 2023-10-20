module Bazaar
	class WholesaleProfile < ApplicationRecord


		has_many :wholesale_items
		has_many :offers, through: :wholesale_items

		enum status: { 'trash' => -1, 'draft' => 0, 'active' => 1, 'archived' => 2 }

		has_many_attached :embedded_attachments

		accepts_nested_attributes_for :wholesale_items

		def get_price( options )
			if ( item_polymorphic_id = options.delete(:item_polymorphic_id) ).present?
				options[:item_type], options[:item_id] = self.class.parse_polymorphic_id( item_polymorphic_id )
			end

			quantity = options.delete(:quantity) || 0

			WholesaleItem.unscoped.joins(:offer).where( wholesale_profile: self ).where( options ).where( '? >= bazaar_offers.min_quantity', quantity ).order( Arel.sql('bazaar_offers.min_quantity desc') ).first.try(:price)
		end

		def items
			Bazaar::Product.where( id: wholesale_items.where( item_type: Bazaar::Product.name ).select(:item_id) )
		end

	end
end
