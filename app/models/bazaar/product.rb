module Bazaar
	class Product < ApplicationRecord


		include Pulitzer::Concerns::UrlConcern
		include Bazaar::Concerns::MoneyAttributesConcern
		include SwellId::Concerns::PolymorphicIdentifiers
		include FriendlyId
		include Bazaar::ProductSearchable if (Bazaar::ProductSearchable rescue nil)

		enum status: { 'draft' => 0, 'active' => 1, 'archive' => 2, 'trash' => 3 }
		enum availability: { 'backorder' => -1, 'pre_order' => 0, 'open_availability' => 1 }
		enum package_shape: { 'no_shape' => 0, 'letter' => 1, 'box' => 2, 'cylinder' => 3 }

		validates		:title, presence: true, unless: :allow_blank_title?

		attr_accessor	:category_name
		attr_accessor	:slug_pref

		has_many :offers
		belongs_to :offer, required: false
		belongs_to 	:product_category, foreign_key: :category_id, required: false
		has_many 	:product_options

		has_one_attached :avatar_attachment
		has_many_attached :embedded_attachments
		has_many_attached :gallery_attachments
		has_many_attached :other_attachments

		before_save		:set_avatar
		before_save	:set_publish_at

		money_attributes :price, :suggested_price, :shipping_price, :purchase_price
		mounted_at '/store'
		friendly_id :slugger, use: [ :slugged, :history ]
		acts_as_taggable_array_on :tags


		def self.published( args = {} )
			where( "bazaar_products.publish_at <= :now", now: Time.zone.now ).active
		end

		def bazaar_uid
			"product_#{self.id}"
		end


		def gtins_csv
			self.gtins.join(',')
		end

		def gtins_csv=(gtins_csv)
			self.gtins = gtins_csv.split(/,\s*/)
		end

		def mpns_csv
			self.mpns.join(',')
		end

		def mpns_csv=(mpns_csv)
			self.mpns = mpns_csv.split(/,\s*/)
		end

		def page_event_data
			data = {
				id: bazaar_uid,
				name: self.title,
				price: self.price_as_money,
				category: nil,
			}

			data[:brand] = self.brand if self.brand.present?
			data[:category] = self.product_category.name if self.product_category.present?

			data
		end

		def page_meta
			if self.title.present?
				title = "#{self.title} )°( #{Pulitzer.app_name}"
			else
				title = Pulitzer.app_name
			end

			schema_org = {
				'@type' => 'Product',
				'url' => self.url,
				'description' => self.description,
				'name' => self.title,
				'datePublished' => self.publish_at.iso8601,
				'image' => self.avatar,
				'offers' => {
					'@type' => 'Offer',
					'availability' => ( self.open_availability? ? 'http://schema.org/InStock' : 'http://schema.org/OutOfStock' ),
					'price' => self.price_as_money_string,
					'priceCurrency' => self.currency,
				}
			}

			# schema_org = schema_org.merge(
			# 	'aggregateRating' => {
			# 		'@type' => 'AggregateRating',
			# 		'ratingValue' => self.rating,
			# 		'reviewCount' => ,
			# 	},
			# 	'review' => reviews.collect{|review| review.page_event_data }
			# )

			return {
				page_title: title,
				title: self.title,
				description: self.sanitized_description,
				image: self.avatar,
				url: self.url,
				twitter_format: 'summary_large_image',
				type: 'Product',
				og: {
					"article:published_time" => self.publish_at.iso8601,
					"product:price:amount" => self.price / 100.to_f,
					"product:price:currency" => 'USD'
				},
				data: schema_org,
			}
		end

		def product_title
			self.title
		end

		def product_url
			self.url
		end

		def published?
			active? && publish_at < Time.zone.now
		end

		def purchase_price
			self.price
		end

		# e.g. Product.record_search( category_name: 'Shirts', text: 'live amrap' )
		# e.g. Product.record_search( category_id: 1, text: 'live amrap' )
		# e.g. Product.record_search( text: 'live amrap' )
		# e.g. Product.record_search( 'live amrap' )
		def self.record_search( options = {} )
			options = { text: options } if options.is_a? String
			page = options.delete(:page)
			per = options.delete(:per) || 10

			query = Jbuilder.encode do |json|
				json.query do

					json.bool do
						json.must do
							if options[:tags].present?

								json.child! do
									json.nested do
										json.path 'tags'
										json.query do
											if options[:tags].is_a? Array
												json.terms do
													json.set! 'tags.raw_name_downcase', options[:tags].collect(&:downcase)
												end
											else
												json.term do
													json.set! 'tags.raw_name_downcase', options[:tags].downcase
												end
											end
										end
									end
								end

							end

							if options.has_key? :published?
								json.child! do
									json.term do
										json.published? options[:published?]
									end
								end
							end

							if options[:category_name].present?
								json.child! do
									json.term do
										json.raw_category_name options[:category_name]
									end
								end
							end

							if options[:category_id].present?
								json.child! do
									json.term do
										json.category_id options[:category_id]
									end
								end
							end
						end

						json.should do

							if options[:text].present?
								json.child! do
									json.match do
										json.title do
											json.query options[:text]
											json.boost 10
										end
									end
								end

								json.child! do
									json.match do
										json.description do
											json.query options[:text]
										end
									end
								end

								json.child! do
									json.match do
										json.category_name do
											json.query options[:text]
										end
									end
								end
							end

						end

						json.minimum_should_match 1

					end
				end
			end

			# puts query.to_json



			self.search( query ).page( page ).per( per ).records

		end

		def sanitized_content
			ActionView::Base.full_sanitizer.sanitize( self.content )
		end

		def sanitized_description
			ActionView::Base.full_sanitizer.sanitize( self.description )
		end

		def slugger
			if self.slug_pref.present?
				self.slug = nil # friendly_id 5.0 only updates slug if slug field is nil
				return self.slug_pref
			else
				return self.title
			end
		end

		def tags_csv
			self.tags.join(',')
		end

		def tags_csv=(tags_csv)
			self.tags = tags_csv.split(/,\s*/)
		end

		def to_s
			self.title
		end

		def as_indexed_json(options={})
			{
				id:					self.id,
				category_id:		self.category_id,
				category_name:		self.product_category.try( :name ),
				raw_category_name:	self.product_category.try( :name ),
				slug:				self.slug,
				created_at:			self.created_at,
				title: 				self.title,
				title_downcase_raw: self.title.try(:downcase),
				description:		self.description,
				published?:			self.published?,
				tags:				self.tags.collect{ |tag| { name: tag, raw_name: tag, name_downcase: tag.downcase, raw_name_downcase: tag.downcase } },
			}.as_json
		end

		protected

			def set_avatar
				self.avatar = self.avatar_attachment.url if self.avatar_attachment.attached?
			end

		private
			def allow_blank_title?
				self.slug_pref.present?
			end

			def set_publish_at
				# set publish_at
				self.publish_at ||= Time.zone.now
			end

	end
end
