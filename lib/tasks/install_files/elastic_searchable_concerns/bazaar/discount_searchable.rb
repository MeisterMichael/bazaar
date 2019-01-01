module Bazaar
	module DiscountSearchable
		extend ActiveSupport::Concern

		included do
			include Searchable

			settings index: { number_of_shards: 1 } do
				mappings dynamic: 'false' do
					indexes :id, type: 'integer'
					indexes :created_at, type: 'date'
					indexes :title, analyzer: 'english', index_options: 'offsets'
					indexes :description, analyzer: 'english', index_options: 'offsets'
					indexes :code, analyzer: 'english', index_options: 'offsets'
				end
			end
		end

		module ClassMethods
			# def class_method_name ... end
		end

		# Instance Methods
		# def instance_method_name ... end

	end

end
