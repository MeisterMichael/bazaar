class SwellAssetsMigration < ActiveRecord::Migration[5.1]
	# V4.0

	def change
		enable_extension 'hstore'

	end
end
