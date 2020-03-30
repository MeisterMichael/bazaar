module Bazaar
	module Concerns

		module UserAddressAttributesConcern
			extend ActiveSupport::Concern

			included do
			end


			####################################################
			# Class Methods

			module ClassMethods

				def accepts_nested_user_address_attributes_for( *user_address_attribute_names )
					user_address_attribute_names = [user_address_attribute_names] unless user_address_attribute_names.is_a? Array

					user_address_attribute_names.each do |user_address_attribute_name|
						geo_address_name = nil
						if user_address_attribute_name.is_a? Array
							geo_address_name = user_address_attribute_name.last
							user_address_attribute_name = user_address_attribute_name.first
						end

						define_method "#{user_address_attribute_name}_attributes=" do |attrs|
							self.try("#{user_address_attribute_name}=", UserAddress.new( geo_address: GeoAddress.new ) ) unless self.try(user_address_attribute_name).present?
							self.try(user_address_attribute_name).attributes = attrs

							self.try(user_address_attribute_name).canonical_geo_address!
							self.try("#{user_address_attribute_name}=", self.try(user_address_attribute_name).canonical_find_or_self )
							self.try("#{geo_address_name}=", self.try(user_address_attribute_name).geo_address )
						end
					end
				end

			end

		end

	end
end
