class SwellMediaMigration < ActiveRecord::Migration
	# V4.0

	def change

		enable_extension 'hstore'

		create_table :categories, force: true do |t|
		t.references		:user 			# created_by
		t.references 		:parent
		t.string			:name
		t.string 			:type
		t.integer 			:lft
		t.integer 			:rgt
		t.text				:description
		t.string			:avatar
		t.string			:cover_image
		t.integer			:status, 						default: 1
		t.integer			:availability, 					default: 1 	# anyone, logged_in, just_me
		t.integer 			:seq
		t.string 			:slug
		t.hstore			:properties, default: {}
		t.timestamps
	end
	add_index :categories, :user_id
	add_index :categories, :parent_id
	add_index :categories, :type
	add_index :categories, :lft
	add_index :categories, :rgt
	add_index :categories, :slug, unique: true


	create_table :contacts do |t|
		t.string		:email
		t.string		:name
		t.string		:subject
		t.text			:message
		t.string		:type
		t.string		:ip
		t.string		:sub_type
		t.string		:http_referrer
		t.integer		:status, 							default: 1
		t.hstore		:properties, default: {}
		t.timestamps
	end
	add_index :contacts, [ :email, :type ]


	create_table :friendly_id_slugs do |t|
		t.string   :slug, 				null: false
		t.integer  :sluggable_id, 		null: false
		t.string   :sluggable_type,		limit: 50
		t.string   :scope
		t.datetime :created_at
	end
	add_index :friendly_id_slugs, :sluggable_id
	add_index :friendly_id_slugs, [:slug, :sluggable_type]
	add_index :friendly_id_slugs, [:slug, :sluggable_type, :scope], unique: true
	add_index :friendly_id_slugs, :sluggable_type


	create_table :media do |t|
		t.references	:user 					# User who added it
		t.references	:managed_by 			# User acct that has origin acct (e.g. youtube) rights
		t.string		:public_id				# public id to spoof sequential id grepping
		t.references 	:category
		t.references 	:avatar_asset

		t.references :working_media_version

		t.references	:parent 				# for nested_set (podcasts + episodes, conversations, etc.)
		t.integer		:lft
		t.integer		:rgt

		t.string		:type 					# video, product, page, article, etc...
		t.string		:sub_type				# video, tv, dvd

		t.string		:title
		t.string		:subtitle
		t.text			:avatar
		t.string		:cover_image
		t.string		:avatar_caption
		t.string		:layout
		t.string		:template				# for future
		t.text			:description
		t.text			:content
		t.string		:slug
		t.string		:redirect_url

		t.boolean 		:is_commentable, 				default: true
		t.boolean		:is_sticky,						default: false 		# for forum topics
		t.boolean		:show_title,					default: true
		t.datetime		:modified_at 								# because updated_at is inadequate when caching stats, etc.
		t.text			:keywords, 	array: true, 		default: []

		t.string		:duration
		t.integer		:cached_char_count, 			default: 0
		t.integer		:cached_word_count, 			default: 0

		t.integer		:status, 						default: 1
		t.integer		:availability, 					default: 1	# anyone, logged_in, just_me
		t.datetime		:publish_at
		t.hstore		:properties, default: {}
		t.string 		:tags, array: true, default: '{}'

		t.timestamps
	end

	add_index :media, :tags, using: 'gin'
	add_index :media, :user_id
	add_index :media, :managed_by_id
	add_index :media, :public_id
	add_index :media, :category_id
	add_index :media, :slug, unique: true
	add_index :media, [ :slug, :type ]
	add_index :media, [ :status, :availability ]

	create_table :media_versions do |t|
		t.references 	:media
		t.references	:user
		t.integer			:status, 						default: 1
		t.json				:versioned_attributes, default: '{}'

		t.timestamps
	end
	add_index :media_versions, [ :media_id, :id ]
	add_index :media_versions, [ :media_id, :status, :id ]

end
end
