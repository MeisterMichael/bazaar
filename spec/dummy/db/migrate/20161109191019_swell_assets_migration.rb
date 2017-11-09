class SwellAssetsMigration < ActiveRecord::Migration
	# V4.0

	def change
		enable_extension 'hstore'

		create_table :assets do |t|
			t.references 	:parent_obj, polymorphic: true
			t.references	:user
			t.string		:title
			t.string		:description # use for caption
			t.text			:content # jic it is a chunk of html or caching entire webpage or something

			t.string		:type # jic want to sti someday....
			t.string		:sub_type # to use e.g. to designate one image as primary avatar
			t.string		:use, default: nil  # e.g. avatar, thumbnail
			t.string		:asset_type, default: 'image'

			t.string		:origin_name
			t.string		:origin_identifier
			t.text			:origin_url

			t.text			:upload # location for CW

			t.integer		:height
			t.integer		:width
			t.integer		:duration

			t.integer		:status, 						default: 1
			t.integer		:availability, 					default: 1	# anyone, logged_in, just_me

			t.hstore		:properties, default: {}
			t.timestamps
		end

		add_index :assets, [ :parent_obj_type, :parent_obj_id ]
		add_index :assets, [:parent_obj_id, :parent_obj_type, :asset_type, :use], name: 'swell_media_asset_use_index'

	end
end
