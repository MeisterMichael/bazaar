module Bazaar
	class OrderItem < ApplicationRecord

		include Bazaar::Concerns::MoneyAttributesConcern
		include SwellId::Concerns::PolymorphicIdentifiers

		enum order_item_type: { 'prod' => 1, 'tax' => 2, 'shipping' => 3, 'discount' => 4 }

		before_create :create_offer_relations!

		belongs_to :item, polymorphic: true, required: false
		belongs_to :order

		belongs_to :subscription, required: false, validate: true

		money_attributes :subtotal, :price

		def create_offer_relations!
			return unless self.prod?
			offer = self.item.offer

			offer_price = offer.offer_prices.active.for_interval( 1 ).first.price
			new_order_offer = self.order.order_offers.new( offer: offer, tax_code: offer.tax_code, title: offer.title, quantity: self.quantity, price: offer_price, subtotal: offer_price * self.quantity )
			new_order_offer.subscription = self.item if self.item.is_a? Bazaar::Subscription
			new_order_offer.subscription_interval = Bazaar::OrderOffer.joins(:order).merge(Bazaar::Order.positive_status).where( subscription: new_order_offer.subscription ).maximum(:subscription_interval).to_i + 1 if new_order_offer.subscription

			new_order_offer.offer.offer_skus.active.for_interval( new_order_offer.subscription_interval ).each do |offer_sku|
				order_sku = self.order.order_skus.to_a.find{ |order_sku| order_sku.sku == offer_sku.sku }
				order_sku ||= self.order.order_skus.new( sku: offer_sku.sku, quantity: 0 )
				order_sku.quantity = order_sku.quantity + offer_sku.calculate_quantity( new_order_offer.quantity )
				order_sku.save!
			end

			new_order_offer.save!

			new_order_offer
		end

		def item_interval
			subscription = self.subscription
			subscription ||= self.item if self.item.is_a? Bazaar::Subscription

			interval = 1
			interval = subscription.orders.where( created_at: Time.at(0)..self.order.created_at ).count if subscription.present?
			interval
		end

		def offer_skus
			package_item.offer_skus.for_interval( self.item_interval )
		end

		def order_offer
			offer = self.item.offer
			self.order.order_offers.to_a.find{ |order_offer| order_offer.offer == offer }
		end

		def package_item
			package_item = self.item
			package_item = package_item.subscription_plan if package_item.is_a? Bazaar::Subscription
			package_item
		end

		def package_shape
			self.properties['package_shape'] || package_item.package_shape
		end

		def package_weight
			return self.properties['package_weight'].to_f if self.properties['package_weight']
			package_item.package_weight
		end

		def package_length
			return self.properties['package_length'].to_f if self.properties['package_length']
			package_item.package_length
		end

		def package_width
			return self.properties['package_width'].to_f if self.properties['package_width']
			package_item.package_width
		end

		def package_height
			return self.properties['package_height'].to_f if self.properties['package_height']
			package_item.package_height
		end



	end
end
