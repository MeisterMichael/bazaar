
module SwellEcom
	class TaxRate < ActiveRecord::Base 
		self.table_name = 'tax_rates'

		belongs_to :geo_state

	end
end

