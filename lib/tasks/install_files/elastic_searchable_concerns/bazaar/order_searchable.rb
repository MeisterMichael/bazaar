module BazaarWeb
	module OrderSearchable
		extend ActiveSupport::Concern

		included do
			include Searchable

			settings index: { number_of_shards: 1 } do
				mappings dynamic: 'false' do
					indexes :id, type: 'integer'
					indexes :created_at, type: 'date'
					indexes :code, analyzer: 'english', index_options: 'offsets'
					indexes :email, analyzer: 'english', index_options: 'offsets'
					indexes :billing_address, analyzer: 'english', index_options: 'offsets'
					indexes :shipping_address, analyzer: 'english', index_options: 'offsets'
					indexes :public, type: 'boolean'
				end
			end
		end

		module ClassMethods
			# def class_method_name ... end
		end

		# Instance Methods
		# def instance_method_name ... end
		def as_indexed_json(options={})
			data = as_json()
			data.merge!( 'billing_address' => billing_address.try(:full_text) || '' ) if self.respond_to? :billing_address
			data.merge!( 'shipping_address' => shipping_address.try(:full_text) || '' ) if self.respond_to? :shipping_address
			data
		end


	end

end
