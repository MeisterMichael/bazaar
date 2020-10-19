module BazaarCore
	class CollectionItem < ApplicationRecord
		include SwellId::Concerns::PolymorphicIdentifiers


		belongs_to :collection
		belongs_to :item, polymorphic: true

	end
end
