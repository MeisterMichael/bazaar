# desc "Explaining what the task does"
namespace :swell_ecom do
	task :install do
		puts "installing"

		prefix = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
		source = File.join( Gem.loaded_specs["swell_ecom"].full_gem_path, "lib/tasks/install_files", 'swell_ecom_migration.rb' )

		target = File.join( Rails.root, 'db/migrate', "#{prefix}_swell_ecom_migration.rb" )

		FileUtils.cp_r source, target

	end

	task seed_usa: :environment do
		usa = SwellEcom::GeoCountry.create(name: 'United States', abbrev: 'USA')
		state_list = [ { name: "ALABAMA", abbrev: "AL"}, { name: "ALASKA", abbrev: "AK"}, { name: "ARIZONA", abbrev: "AZ"}, { name: "ARKANSAS", abbrev: "AR"}, { name: "CALIFORNIA", abbrev: "CA"}, { name: "COLORADO", abbrev: "CO"}, { name: "CONNECTICUT", abbrev: "CT"}, { name: "DELAWARE", abbrev: "DE"}, { name: "FLORIDA", abbrev: "FL"}, { name: "GEORGIA", abbrev: "GA"}, { name: "HAWAII", abbrev: "HI"}, { name: "IDAHO", abbrev: "ID"}, { name: "ILLINOIS", abbrev: "IL"}, { name: "INDIANA", abbrev: "IN"}, { name: "IOWA", abbrev: "IA"}, { name: "KANSAS", abbrev: "KS"}, { name: "KENTUCKY", abbrev: "KY"}, { name: "LOUISIANA", abbrev: "LA"}, { name: "MAINE", abbrev: "ME"}, { name: "MARYLAND", abbrev: "MD"}, { name: "MASSACHUSETTS", abbrev: "MA"}, { name: "MICHIGAN", abbrev: "MI"}, { name: "MINNESOTA", abbrev: "MN"}, { name: "MISSISSIPPI", abbrev: "MS"}, { name: "MISSOURI", abbrev: "MO"}, { name: "MONTANA", abbrev: "MT"}, { name: "NEBRASKA", abbrev: "NE"}, { name: "NEVADA", abbrev: "NV"}, { name: "NEW HAMPSHIRE", abbrev: "NH"}, { name: "NEW JERSEY", abbrev: "NJ"}, { name: "NEW MEXICO", abbrev: "NM"}, { name: "NEW YORK", abbrev: "NY"}, { name: "NORTH CAROLINA", abbrev: "NC"}, { name: "NORTH DAKOTA", abbrev: "ND"}, { name: "OHIO", abbrev: "OH"}, { name: "OKLAHOMA", abbrev: "OK"}, { name: "OREGON", abbrev: "OR"}, { name: "PENNSYLVANIA", abbrev: "PA"}, { name: "RHODE ISLAND", abbrev: "RI"}, { name: "SOUTH CAROLINA", abbrev: "SC"}, { name: "SOUTH DAKOTA", abbrev: "SD"}, { name: "TENNESSEE", abbrev: "TN"}, { name: "TEXAS", abbrev: "TX"}, { name: "UTAH", abbrev: "UT"}, { name: "VERMONT", abbrev: "VT"}, { name: "VIRGINIA", abbrev: "VA"}, { name: "WASHINGTON", abbrev: "WA"}, { name: "WEST VIRGINIA", abbrev: "WV"}, { name: "WISCONSIN", abbrev: "WI"}, { name: "WYOMING", abbrev: "WY" } ]
		state_list.each do |state_data|
			SwellEcom::GeoState.create( state_data.merge( geo_country: usa ) )
		end
	end
end
