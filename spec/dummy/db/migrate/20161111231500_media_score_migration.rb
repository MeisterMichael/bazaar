class MediaScoreMigration < ActiveRecord::Migration

	def change

		add_column :media, :score, :float, default: 1.0
		add_index :media, [ :score, :category_id, :status, :publish_at ]
		add_index :media, [ :score, :status, :publish_at ]

		add_column :media, :featured, :integer, default: 0
		add_index :media, [ :featured, :category_id, :status, :publish_at, :score ], name: 'index_media_on_featured_and_category_and_status_and_publish'
		add_index :media, [ :featured, :status, :publish_at, :score ], name: 'index_media_on_featured_and_status_and_publish'

	end
end
