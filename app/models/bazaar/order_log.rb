module Bazaar
	class OrderLog < ApplicationRecord

		belongs_to :item, polymorphic: true, required: false
		belongs_to :order

		enum log_type: { 'critical' => -300, 'error' => -200, 'warning' => -100, 'debug' => 0, 'info' => 
			100, 'success' => 200 }
	end
end
