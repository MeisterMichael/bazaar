# desc "Explaining what the task does"
namespace :bazaar do

	task cached_discount_stats_backfill: :environment do

    # a list of all discounts used in active orders.
    discount_order_items = Bazaar::OrderItem.discount.joins( :order ).merge( Bazaar::Order.active )

    Bazaar::Discount.all.find_each do |discount|

      discount.cached_uses = discount_order_items.where( item: discount ).count
      discount.save

    end

	end

	task cached_discount_stats_update: :environment do

    date_range = 1.day.ago..Time.now

    # a list of all discounts used in active orders.
    discount_order_items = Bazaar::OrderItem.discount.joins( :order ).merge( Bazaar::Order.active )

    updated_discounts_ids = discount_order_items.where( created_at: date_range ).select(:item_id)

    Bazaar::Discount.where( id: updated_discounts_ids ).find_each do |discount|

      discount.cached_uses = discount_order_items.where( item: discount ).count
      discount.save

    end

	end

end
