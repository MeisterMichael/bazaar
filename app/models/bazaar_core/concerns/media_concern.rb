module BazaarCore
	module Concerns

		module MediaConcern
			extend ActiveSupport::Concern

			included do
				include Pulitzer::Concerns::URLConcern
				include FriendlyId

				belongs_to :user
				belongs_to :managed_by, class_name: 'User', optional: true
				belongs_to :category, optional: true
				belongs_to :parent, optional: true

				enum status: { 'draft' => 0, 'active' => 1, 'archive' => 100, 'trash' => -50 }
				enum availability: { 'anyone' => 1, 'logged_in_users' => 2, 'just_me' => 3 }

				before_create	:set_template_and_layout
				before_save		:set_publish_at, :set_keywords_and_tags, :set_cached_counts, :set_avatar

				validates		:title, presence: true, unless: :allow_blank_title?

				attr_accessor	:category_name

				has_one_attached :avatar_attachment
				has_one_attached :cover_attachment
				has_many_attached :embedded_attachments
				has_many_attached :other_attachments

				friendly_id :slugger, use: [ :slugged, :history ]

				acts_as_nested_set

				acts_as_taggable_array_on :tags


			end


			####################################################
			# Class Methods

			module ClassMethods


				def media_tag_cloud( args = {} )
					args[:limit] ||= 7
					media_relation = self.limit(nil)
					return Pulitzer::Media.unscoped.limit( args[:limit] ).tags_cloud{ merge( media_relation ) }.to_a
				end

				# def self.other_attachments_with_tags( tags = [] )
				# 	query = self.all
				# 	tags.each do |tag|
				# 		query = query.where( "? = ANY(annotations)", tag )
				# 	end
				# 	query
				# end


				def published( args = {} )
					where( "bazaar_media.publish_at <= :now", now: Time.zone.now ).active.anyone
				end

			end


			####################################################
			# Instance Methods

			def published?
				active? && anyone? && publish_at < Time.zone.now
			end


			# Instance Methods


			def author
				if self.properties.present?
					return self.properties['author_name']
				elsif self.user.present?
					return self.user.to_s
				else
					return ''
				end
			end

			def category_name=( name )
				self.category = Pulitzer::Category.where( name: name ).first_or_create
			end

			def char_count
				return 0 if self.content.blank?
				self.sanitized_content.gsub(URI.regexp(['http', 'https']), '').size
			end

			def comments( args = {} )
				user_posts = SwellSocial::UserPost.where( parent_obj_id: self.id, parent_obj_type: self.class.name )
				user_posts.order( created_at: (args[:order] || :desc) )
			end

			def page_meta
				if self.title.present?
					title = "#{self.title} | #{Pulitzer.app_name}"
				else
					title = Pulitzer.app_name
				end

				return {
					page_title: title,
					title: self.title,
					description: self.sanitized_description,
					image: self.avatar,
					url: self.url,
					twitter_format: 'summary_large_image',
					type: 'article',
					og: {
						"article:published_time" => self.publish_at.iso8601,
						"article:author" => self.user.to_s
					},
					data: {
						'url' => self.url,
						'name' => self.title,
						'description' => self.sanitized_description,
						'datePublished' => self.publish_at.iso8601,
						'author' => self.user.to_s,
						'image' => self.avatar
					}

				}
			end

			# def new_embedded_attachments=( attachments )
			# 	self.embedded_attachments.attach( attachments )
			# end

			# def new_other_attachments=( attachments )
			# 	self.other_attachments.attach( attachments )
			# end


			def sanitized_content
				ActionView::Base.full_sanitizer.sanitize( self.content )
			end

			def sanitized_description
				ActionView::Base.full_sanitizer.sanitize( self.description )
			end

			def should_generate_new_friendly_id?
				self.slug.nil? || self.slug_pref.present?
			end

			def slugger
				if self.slug_pref.present?
					self.slug = nil # friendly_id 5.0 only updates slug if slug field is nil
					return self.slug_pref
				else
					return self.title
				end
			end

			def slug_pref
				@slug_pref
			end

			def slug_pref=(val)
				self.slug = nil if val.present?
				@slug_pref = val
			end

			def tags_csv
				self.tags.join(',')
			end

			def tags_csv=(tags_csv)
				self.tags = tags_csv.split(/,\s*/)
			end

			def to_s
				self.title.present? ? self.title : self.slug
			end

			def word_count
				return 0 if self.content.blank?
				self.sanitized_content.gsub(URI.regexp(['http', 'https']), '').scan(/[\w-]+/).size
			end


			private

				def allow_blank_title?
					self.slug_pref.present?
				end

				def set_avatar
					self.avatar = self.avatar_attachment.service_url if self.avatar_attachment.attached?
					self.cover_image = self.cover_attachment.service_url if self.cover_attachment.attached?
				end

				def set_cached_counts
					if self.respond_to?( :cached_word_count )
						self.cached_word_count = self.word_count
					end

					if self.respond_to?( :cached_char_count )
						self.cached_char_count = self.char_count
					end
				end

				def set_publish_at
					# set publish_at
					self.publish_at ||= Time.zone.now
				end

				def set_keywords_and_tags
					common_terms = ["able", "about", "above", "across", "after", "almost", "also", "among", "around", "back", "because", "been", "below", "came", "cannot", "come", "cool", "could", "dear", "does", "down", "each", "either", "else", "ever", "every", "find", "first", "from", "from", "gave", "give", "goodhave", "have", "hers", "however", "inside", "into", "its", "just", "least", "like", "likely", "little", "live", "long", "made", "make", "many", "might", "more", "most", "must", "neither", "number", "often", "only", "other", "our", "outside", "over", "part", "people", "place", "rather", "said", "says", "should", "show", "side", "since", "some", "sound", "take", "than", "that", "the", "their", "them",  "then", "there", "these", "they", "thing", "this", "those", "time", "twas", "under", "upon", "was", "wants", "were", "what", "whatever", "when", "where", "which", "while", "whom", "will", "with", "within", "work", "would", "write", "year", "you", "your"]

					# auto-tag hashtags
					unless self.description.blank?
						# hashtags must start with a # and must contain at least one letter
						hashtags = self.sanitized_description.scan( /#([a-zA-Z_0-9]*[a-zA-Z][a-zA-Z_0-9]*)/ ).flatten.uniq
						new_tags = (hashtags + self.tags).uniq.sort

						self.tags = new_tags unless new_tags & (self.tags || []) == new_tags
					end

					new_keywords = "#{self.author} #{self.title}".downcase.split( /\W/ ).delete_if{ |elem| elem.length <= 2 }.delete_if{ |elem| common_terms.include?( elem ) }.uniq
					self.tags.each{ |tag| new_keywords << tag.to_s unless new_keywords.include?( tag.to_s )}

					new_keywords = new_keywords.uniq.sort

					self.keywords = new_keywords unless new_keywords & (self.keywords || []) == new_keywords

				end

				def set_template_and_layout
					self.layout ||= 'application'
					self.template ||= "#{self.class.name.underscore.pluralize}/show"
				end



		end

	end
end
