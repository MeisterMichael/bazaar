class SwellEcomOrderProviderReferenceMigration < ActiveRecord::Migration[5.1]
	def change

		add_column :orders, :provider_reference, :string, default: nil

	end
end
