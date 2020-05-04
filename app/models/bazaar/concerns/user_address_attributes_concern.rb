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
							geo_address_name = user_address_attribute_name[1]
							user_id_attribute_name = user_address_attribute_name[2]
							user_address_attribute_name = user_address_attribute_name[0]
						end

						define_method "#{user_address_attribute_name}_attributes=" do |attrs|

							self.try("#{user_address_attribute_name}=", UserAddress.new( geo_address: GeoAddress.new ) ) unless self.try(user_address_attribute_name).present?
							self.try(user_address_attribute_name).attributes = attrs

							self.try(user_address_attribute_name).user_id ||= self.try(user_id_attribute_name) if user_id_attribute_name

							self.try(user_address_attribute_name).canonical_geo_address!
							self.try("#{user_address_attribute_name}=", self.try(user_address_attribute_name).canonical_find_or_self )
							self.try("#{geo_address_name}=", self.try(user_address_attribute_name).geo_address ) if geo_address_name

						end
					end

					define_method "backfill_user_addresses" do
						copy_attribute_names = [:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name, :tags, :preferred, :properties, :user].collect(&:to_s)

						user_address_attribute_names.each do |user_address_attribute_name|
							geo_address_name = nil
							if user_address_attribute_name.is_a? Array
								geo_address_name = user_address_attribute_name[1]
								user_id_attribute_name = user_address_attribute_name[2]
								user_address_attribute_name = user_address_attribute_name[0]
							end

							if geo_address_name.present? && self.try(geo_address_name).present? && self.try(user_address_attribute_name).nil?
								geo_address_id_name = "#{geo_address_name}_id"

								geo_address = self.try(geo_address_name)

								user_id = geo_address.user_id
								user_id ||= self.try(user_id_attribute_name) if user_id_attribute_name
								user = ::User.find( user_id ) if user_id

								self.try( "#{user_address_attribute_name}_attributes=", geo_address.attributes.slice(*copy_attribute_names).merge( 'user': user ) )
								self.try( "#{geo_address_id_name}=", (geo_address.id || self.try(geo_address_id_name)) )
							end
						end
					end

					define_method "backfill_user_addresses!" do
						self.backfill_user_addresses
						self.save!
					end


				end

			end

		end

	end
end
