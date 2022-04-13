class ShipmentExternalReferenceMigration < ActiveRecord::Migration[5.2]
	def change
		change_table	:bazaar_shipments do |t|
			t.string 	:source_identifier, default: nil
			t.string 	:source_system, default: nil
			t.index ['source_identifier', 'source_system']
			t.index ['source_system']
		end
	end
end
