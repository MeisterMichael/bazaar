class BazaarMediaMigration < ActiveRecord::Migration[5.1]
	def change

		create_table :bazaar_media do |t|
			t.belongs_to :user
			t.belongs_to :managed_by
			t.belongs_to :category
			t.belongs_to :parent
	    t.bigint :working_media_version_id
	    t.integer :lft
	    t.integer :rgt
	    t.string :type
	    t.string :sub_type
	    t.string :title
	    t.string :subtitle
	    t.text :avatar
	    t.string :cover_image
	    t.string :avatar_caption
	    t.string :layout
	    t.string :template
	    t.text :description
	    t.text :content
	    t.string :slug
	    t.string :redirect_url
	    t.boolean :is_commentable, default: true
	    t.boolean :is_sticky, default: false
	    t.boolean :show_title, default: true
	    t.text :keywords, default: [], array: true
	    t.string :duration
	    t.integer :cached_char_count, default: 0
	    t.integer :cached_word_count, default: 0
	    t.integer :status, default: 1
	    t.integer :availability, default: 1
	    t.datetime :publish_at
	    t.hstore :properties, default: {}
	    t.string :tags, default: [], array: true
	    t.integer :seq
	    t.text :meta_description
			t.timestamps

	    t.index [:slug, :type]
	    t.index [:slug], unique: true
	    t.index [:status, :availability]
	    t.index [:tags], using: :gin
	    t.index [:working_media_version_id]
		end

		create_table :bazaar_media_offers do |t|
			t.belongs_to :media
			t.belongs_to :offer
	    t.integer :seq
	    t.index [:media_id,:seq], unique: true
		end

	end
end
