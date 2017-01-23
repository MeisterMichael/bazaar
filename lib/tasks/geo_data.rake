namespace :swell_ecom do
	task load_geo_data: :environment do
		puts "Loading Geo Data"

		puts "Adding Country data"

		usa = 		SwellEcom::GeoCountry.create :abbrev => "US", :name => "United States"
		canada = 	SwellEcom::GeoCountry.create :abbrev => "CA", :name => "Canada"
		uk = 		SwellEcom::GeoCountry.create :abbrev => "GB", :name => "United Kingdom"

		SwellEcom::GeoCountry.create :abbrev => "AF", :name => "Afghanistan"
		SwellEcom::GeoCountry.create :abbrev => "AL", :name => "Albania"
		SwellEcom::GeoCountry.create :abbrev => "DZ", :name => "Algeria"
		SwellEcom::GeoCountry.create :abbrev => "AS", :name => "American Samoa"
		SwellEcom::GeoCountry.create :abbrev => "AD", :name => "Andorra"
		SwellEcom::GeoCountry.create :abbrev => "AO", :name => "Angola"
		SwellEcom::GeoCountry.create :abbrev => "AI", :name => "Anguilla"
		SwellEcom::GeoCountry.create :abbrev => "AQ", :name => "Antarctica"
		SwellEcom::GeoCountry.create :abbrev => "AG", :name => "Antigua and Barbuda"
		SwellEcom::GeoCountry.create :abbrev => "AR", :name => "Argentina"
		SwellEcom::GeoCountry.create :abbrev => "AM", :name => "Armenia"
		SwellEcom::GeoCountry.create :abbrev => "AW", :name => "Aruba"
		SwellEcom::GeoCountry.create :abbrev => "AU", :name => "Australia"
		SwellEcom::GeoCountry.create :abbrev => "AT", :name => "Austria"
		SwellEcom::GeoCountry.create :abbrev => "AZ", :name => "Azerbaidjan"
		SwellEcom::GeoCountry.create :abbrev => "BS", :name => "Bahamas"
		SwellEcom::GeoCountry.create :abbrev => "BH", :name => "Bahrain"
		SwellEcom::GeoCountry.create :abbrev => "BD", :name => "Bangladesh"
		SwellEcom::GeoCountry.create :abbrev => "BB", :name => "Barbados"
		SwellEcom::GeoCountry.create :abbrev => "BY", :name => "Belarus"
		SwellEcom::GeoCountry.create :abbrev => "BE", :name => "Belgium"
		SwellEcom::GeoCountry.create :abbrev => "BZ", :name => "Belize"
		SwellEcom::GeoCountry.create :abbrev => "BJ", :name => "Benin"
		SwellEcom::GeoCountry.create :abbrev => "BM", :name => "Bermuda"
		SwellEcom::GeoCountry.create :abbrev => "BT", :name => "Bhutan"
		SwellEcom::GeoCountry.create :abbrev => "BO", :name => "Bolivia"
		SwellEcom::GeoCountry.create :abbrev => "BA", :name => "Bosnia-Herzegovina"
		SwellEcom::GeoCountry.create :abbrev => "BW", :name => "Botswana"
		SwellEcom::GeoCountry.create :abbrev => "BV", :name => "Bouvet Island"
		SwellEcom::GeoCountry.create :abbrev => "BR", :name => "Brazil"
		SwellEcom::GeoCountry.create :abbrev => "IO", :name => "British Indian Ocean Territory"
		SwellEcom::GeoCountry.create :abbrev => "BN", :name => "Brunei Darussalam"
		SwellEcom::GeoCountry.create :abbrev => "BG", :name => "Bulgaria"
		SwellEcom::GeoCountry.create :abbrev => "BF", :name => "Burkina Faso"
		SwellEcom::GeoCountry.create :abbrev => "BI", :name => "Burundi"
		SwellEcom::GeoCountry.create :abbrev => "KH", :name => "Cambodia"
		SwellEcom::GeoCountry.create :abbrev => "CM", :name => "Cameroon"
		SwellEcom::GeoCountry.create :abbrev => "CV", :name => "Cape Verde"
		SwellEcom::GeoCountry.create :abbrev => "KY", :name => "Cayman Islands"
		SwellEcom::GeoCountry.create :abbrev => "CF", :name => "Central African Republic"
		SwellEcom::GeoCountry.create :abbrev => "TD", :name => "Chad"
		SwellEcom::GeoCountry.create :abbrev => "CL", :name => "Chile"
		SwellEcom::GeoCountry.create :abbrev => "CN", :name => "China"
		SwellEcom::GeoCountry.create :abbrev => "CX", :name => "Christmas Island"
		SwellEcom::GeoCountry.create :abbrev => "CC", :name => "Cocos (Keeling) Islands"
		SwellEcom::GeoCountry.create :abbrev => "CO", :name => "Colombia"
		SwellEcom::GeoCountry.create :abbrev => "KM", :name => "Comoros"
		SwellEcom::GeoCountry.create :abbrev => "CG", :name => "Congo"
		SwellEcom::GeoCountry.create :abbrev => "CK", :name => "Cook Islands"
		SwellEcom::GeoCountry.create :abbrev => "CR", :name => "Costa Rica"
		SwellEcom::GeoCountry.create :abbrev => "HR", :name => "Croatia"
		SwellEcom::GeoCountry.create :abbrev => "CU", :name => "Cuba"
		SwellEcom::GeoCountry.create :abbrev => "CY", :name => "Cyprus"
		SwellEcom::GeoCountry.create :abbrev => "CZ", :name => "Czech Republic"
		SwellEcom::GeoCountry.create :abbrev => "DK", :name => "Denmark"
		SwellEcom::GeoCountry.create :abbrev => "DJ", :name => "Djibouti"
		SwellEcom::GeoCountry.create :abbrev => "DM", :name => "Dominica"
		SwellEcom::GeoCountry.create :abbrev => "DO", :name => "Dominican Republic"
		SwellEcom::GeoCountry.create :abbrev => "TP", :name => "East Timor"
		SwellEcom::GeoCountry.create :abbrev => "EC", :name => "Ecuador"
		SwellEcom::GeoCountry.create :abbrev => "EG", :name => "Egypt"
		SwellEcom::GeoCountry.create :abbrev => "SV", :name => "El Salvador"
		SwellEcom::GeoCountry.create :abbrev => "GQ", :name => "Equatorial Guinea"
		SwellEcom::GeoCountry.create :abbrev => "ER", :name => "Eritrea"
		SwellEcom::GeoCountry.create :abbrev => "EE", :name => "Estonia"
		SwellEcom::GeoCountry.create :abbrev => "ET", :name => "Ethiopia"
		SwellEcom::GeoCountry.create :abbrev => "FK", :name => "Falkland Islands"
		SwellEcom::GeoCountry.create :abbrev => "FO", :name => "Faroe Islands"
		SwellEcom::GeoCountry.create :abbrev => "FJ", :name => "Fiji"
		SwellEcom::GeoCountry.create :abbrev => "FI", :name => "Finland"
		SwellEcom::GeoCountry.create :abbrev => "CS", :name => "Former Czechoslovakia"
		SwellEcom::GeoCountry.create :abbrev => "SU", :name => "Former USSR"
		SwellEcom::GeoCountry.create :abbrev => "FR", :name => "France"
		SwellEcom::GeoCountry.create :abbrev => "FX", :name => "France (European Territory)"
		SwellEcom::GeoCountry.create :abbrev => "GF", :name => "French Guyana"
		SwellEcom::GeoCountry.create :abbrev => "TF", :name => "French Southern Territories"
		SwellEcom::GeoCountry.create :abbrev => "GA", :name => "Gabon"
		SwellEcom::GeoCountry.create :abbrev => "GM", :name => "Gambia"
		SwellEcom::GeoCountry.create :abbrev => "GE", :name => "Georgia"
		SwellEcom::GeoCountry.create :abbrev => "DE", :name => "Germany"
		SwellEcom::GeoCountry.create :abbrev => "GH", :name => "Ghana"
		SwellEcom::GeoCountry.create :abbrev => "GI", :name => "Gibraltar"
		SwellEcom::GeoCountry.create :abbrev => "GB", :name => "Great Britain"
		SwellEcom::GeoCountry.create :abbrev => "GR", :name => "Greece"
		SwellEcom::GeoCountry.create :abbrev => "GL", :name => "Greenland"
		SwellEcom::GeoCountry.create :abbrev => "GD", :name => "Grenada"
		SwellEcom::GeoCountry.create :abbrev => "GP", :name => "Guadeloupe (French)"
		SwellEcom::GeoCountry.create :abbrev => "GU", :name => "Guam (USA)"
		SwellEcom::GeoCountry.create :abbrev => "GT", :name => "Guatemala"
		SwellEcom::GeoCountry.create :abbrev => "GN", :name => "Guinea"
		SwellEcom::GeoCountry.create :abbrev => "GW", :name => "Guinea Bissau"
		SwellEcom::GeoCountry.create :abbrev => "GY", :name => "Guyana"
		SwellEcom::GeoCountry.create :abbrev => "HT", :name => "Haiti"
		SwellEcom::GeoCountry.create :abbrev => "HM", :name => "Heard and McDonald Islands"
		SwellEcom::GeoCountry.create :abbrev => "HN", :name => "Honduras"
		SwellEcom::GeoCountry.create :abbrev => "HK", :name => "Hong Kong"
		SwellEcom::GeoCountry.create :abbrev => "HU", :name => "Hungary"
		SwellEcom::GeoCountry.create :abbrev => "IS", :name => "Iceland"
		SwellEcom::GeoCountry.create :abbrev => "IN", :name => "India"
		SwellEcom::GeoCountry.create :abbrev => "ID", :name => "Indonesia"
		SwellEcom::GeoCountry.create :abbrev => "INT", :name => "International"
		SwellEcom::GeoCountry.create :abbrev => "IR", :name => "Iran"
		SwellEcom::GeoCountry.create :abbrev => "IQ", :name => "Iraq"
		SwellEcom::GeoCountry.create :abbrev => "IE", :name => "Ireland"
		SwellEcom::GeoCountry.create :abbrev => "IL", :name => "Israel"
		SwellEcom::GeoCountry.create :abbrev => "IT", :name => "Italy"
		SwellEcom::GeoCountry.create :abbrev => "CI", :name => "Ivory Coast (Cote D&#39;Ivoire)"
		SwellEcom::GeoCountry.create :abbrev => "JM", :name => "Jamaica"
		SwellEcom::GeoCountry.create :abbrev => "JP", :name => "Japan"
		SwellEcom::GeoCountry.create :abbrev => "JO", :name => "Jordan"
		SwellEcom::GeoCountry.create :abbrev => "KZ", :name => "Kazakhstan"
		SwellEcom::GeoCountry.create :abbrev => "KE", :name => "Kenya"
		SwellEcom::GeoCountry.create :abbrev => "KI", :name => "Kiribati"
		SwellEcom::GeoCountry.create :abbrev => "KW", :name => "Kuwait"
		SwellEcom::GeoCountry.create :abbrev => "KG", :name => "Kyrgyzstan"
		SwellEcom::GeoCountry.create :abbrev => "LA", :name => "Laos"
		SwellEcom::GeoCountry.create :abbrev => "LV", :name => "Latvia"
		SwellEcom::GeoCountry.create :abbrev => "LB", :name => "Lebanon"
		SwellEcom::GeoCountry.create :abbrev => "LS", :name => "Lesotho"
		SwellEcom::GeoCountry.create :abbrev => "LR", :name => "Liberia"
		SwellEcom::GeoCountry.create :abbrev => "LY", :name => "Libya"
		SwellEcom::GeoCountry.create :abbrev => "LI", :name => "Liechtenstein"
		SwellEcom::GeoCountry.create :abbrev => "LT", :name => "Lithuania"
		SwellEcom::GeoCountry.create :abbrev => "LU", :name => "Luxembourg"
		SwellEcom::GeoCountry.create :abbrev => "MO", :name => "Macau"
		SwellEcom::GeoCountry.create :abbrev => "MK", :name => "Macedonia"
		SwellEcom::GeoCountry.create :abbrev => "MG", :name => "Madagascar"
		SwellEcom::GeoCountry.create :abbrev => "MW", :name => "Malawi"
		SwellEcom::GeoCountry.create :abbrev => "MY", :name => "Malaysia"
		SwellEcom::GeoCountry.create :abbrev => "MV", :name => "Maldives"
		SwellEcom::GeoCountry.create :abbrev => "ML", :name => "Mali"
		SwellEcom::GeoCountry.create :abbrev => "MT", :name => "Malta"
		SwellEcom::GeoCountry.create :abbrev => "MH", :name => "Marshall Islands"
		SwellEcom::GeoCountry.create :abbrev => "MQ", :name => "Martinique (French)"
		SwellEcom::GeoCountry.create :abbrev => "MR", :name => "Mauritania"
		SwellEcom::GeoCountry.create :abbrev => "MU", :name => "Mauritius"
		SwellEcom::GeoCountry.create :abbrev => "YT", :name => "Mayotte"
		SwellEcom::GeoCountry.create :abbrev => "MX", :name => "Mexico"
		SwellEcom::GeoCountry.create :abbrev => "FM", :name => "Micronesia"
		SwellEcom::GeoCountry.create :abbrev => "MD", :name => "Moldavia"
		SwellEcom::GeoCountry.create :abbrev => "MC", :name => "Monaco"
		SwellEcom::GeoCountry.create :abbrev => "MN", :name => "Mongolia"
		SwellEcom::GeoCountry.create :abbrev => "MS", :name => "Montserrat"
		SwellEcom::GeoCountry.create :abbrev => "MA", :name => "Morocco"
		SwellEcom::GeoCountry.create :abbrev => "MZ", :name => "Mozambique"
		SwellEcom::GeoCountry.create :abbrev => "MM", :name => "Myanmar"
		SwellEcom::GeoCountry.create :abbrev => "NA", :name => "Namibia"
		SwellEcom::GeoCountry.create :abbrev => "NR", :name => "Nauru"
		SwellEcom::GeoCountry.create :abbrev => "NP", :name => "Nepal"
		SwellEcom::GeoCountry.create :abbrev => "NL", :name => "Netherlands"
		SwellEcom::GeoCountry.create :abbrev => "AN", :name => "Netherlands Antilles"
		SwellEcom::GeoCountry.create :abbrev => "NT", :name => "Neutral Zone"
		SwellEcom::GeoCountry.create :abbrev => "NC", :name => "New Caledonia (French)"
		SwellEcom::GeoCountry.create :abbrev => "NZ", :name => "New Zealand"
		SwellEcom::GeoCountry.create :abbrev => "NI", :name => "Nicaragua"
		SwellEcom::GeoCountry.create :abbrev => "NE", :name => "Niger"
		SwellEcom::GeoCountry.create :abbrev => "NG", :name => "Nigeria"
		SwellEcom::GeoCountry.create :abbrev => "NU", :name => "Niue"
		SwellEcom::GeoCountry.create :abbrev => "NF", :name => "Norfolk Island"
		SwellEcom::GeoCountry.create :abbrev => "KP", :name => "North Korea"
		SwellEcom::GeoCountry.create :abbrev => "MP", :name => "Northern Mariana Islands"
		SwellEcom::GeoCountry.create :abbrev => "NO", :name => "Norway"
		SwellEcom::GeoCountry.create :abbrev => "OM", :name => "Oman"
		SwellEcom::GeoCountry.create :abbrev => "PK", :name => "Pakistan"
		SwellEcom::GeoCountry.create :abbrev => "PW", :name => "Palau"
		SwellEcom::GeoCountry.create :abbrev => "PA", :name => "Panama"
		SwellEcom::GeoCountry.create :abbrev => "PG", :name => "Papua New Guinea"
		SwellEcom::GeoCountry.create :abbrev => "PY", :name => "Paraguay"
		SwellEcom::GeoCountry.create :abbrev => "PE", :name => "Peru"
		SwellEcom::GeoCountry.create :abbrev => "PH", :name => "Philippines"
		SwellEcom::GeoCountry.create :abbrev => "PN", :name => "Pitcairn Island"
		SwellEcom::GeoCountry.create :abbrev => "PL", :name => "Poland"
		SwellEcom::GeoCountry.create :abbrev => "PF", :name => "Polynesia (French)"
		SwellEcom::GeoCountry.create :abbrev => "PT", :name => "Portugal"
		SwellEcom::GeoCountry.create :abbrev => "PR", :name => "Puerto Rico"
		SwellEcom::GeoCountry.create :abbrev => "QA", :name => "Qatar"
		SwellEcom::GeoCountry.create :abbrev => "RE", :name => "Reunion (French)"
		SwellEcom::GeoCountry.create :abbrev => "RO", :name => "Romania"
		SwellEcom::GeoCountry.create :abbrev => "RU", :name => "Russian Federation"
		SwellEcom::GeoCountry.create :abbrev => "RW", :name => "Rwanda"
		SwellEcom::GeoCountry.create :abbrev => "GS", :name => "S. Georgia & S. Sandwich Isls."
		SwellEcom::GeoCountry.create :abbrev => "SH", :name => "Saint Helena"
		SwellEcom::GeoCountry.create :abbrev => "KN", :name => "Saint Kitts & Nevis Anguilla"
		SwellEcom::GeoCountry.create :abbrev => "LC", :name => "Saint Lucia"
		SwellEcom::GeoCountry.create :abbrev => "PM", :name => "Saint Pierre and Miquelon"
		SwellEcom::GeoCountry.create :abbrev => "ST", :name => "Saint Tome (Sao Tome) and Principe"
		SwellEcom::GeoCountry.create :abbrev => "VC", :name => "Saint Vincent & Grenadines"
		SwellEcom::GeoCountry.create :abbrev => "WS", :name => "Samoa"
		SwellEcom::GeoCountry.create :abbrev => "SM", :name => "San Marino"
		SwellEcom::GeoCountry.create :abbrev => "SA", :name => "Saudi Arabia"
		SwellEcom::GeoCountry.create :abbrev => "SN", :name => "Senegal"
		SwellEcom::GeoCountry.create :abbrev => "SC", :name => "Seychelles"
		SwellEcom::GeoCountry.create :abbrev => "SL", :name => "Sierra Leone"
		SwellEcom::GeoCountry.create :abbrev => "SG", :name => "Singapore"
		SwellEcom::GeoCountry.create :abbrev => "SK", :name => "Slovak Republic"
		SwellEcom::GeoCountry.create :abbrev => "SI", :name => "Slovenia"
		SwellEcom::GeoCountry.create :abbrev => "SB", :name => "Solomon Islands"
		SwellEcom::GeoCountry.create :abbrev => "SO", :name => "Somalia"
		SwellEcom::GeoCountry.create :abbrev => "ZA", :name => "South Africa"
		SwellEcom::GeoCountry.create :abbrev => "KR", :name => "South Korea"
		SwellEcom::GeoCountry.create :abbrev => "ES", :name => "Spain"
		SwellEcom::GeoCountry.create :abbrev => "LK", :name => "Sri Lanka"
		SwellEcom::GeoCountry.create :abbrev => "SD", :name => "Sudan"
		SwellEcom::GeoCountry.create :abbrev => "SR", :name => "Suriname"
		SwellEcom::GeoCountry.create :abbrev => "SJ", :name => "Svalbard and Jan Mayen Islands"
		SwellEcom::GeoCountry.create :abbrev => "SZ", :name => "Swaziland"
		SwellEcom::GeoCountry.create :abbrev => "SE", :name => "Sweden"
		SwellEcom::GeoCountry.create :abbrev => "CH", :name => "Switzerland"
		SwellEcom::GeoCountry.create :abbrev => "SY", :name => "Syria"
		SwellEcom::GeoCountry.create :abbrev => "TJ", :name => "Tadjikistan"
		SwellEcom::GeoCountry.create :abbrev => "TW", :name => "Taiwan"
		SwellEcom::GeoCountry.create :abbrev => "TZ", :name => "Tanzania"
		SwellEcom::GeoCountry.create :abbrev => "TH", :name => "Thailand"
		SwellEcom::GeoCountry.create :abbrev => "TG", :name => "Togo"
		SwellEcom::GeoCountry.create :abbrev => "TK", :name => "Tokelau"
		SwellEcom::GeoCountry.create :abbrev => "TO", :name => "Tonga"
		SwellEcom::GeoCountry.create :abbrev => "TT", :name => "Trinidad and Tobago"
		SwellEcom::GeoCountry.create :abbrev => "TN", :name => "Tunisia"
		SwellEcom::GeoCountry.create :abbrev => "TR", :name => "Turkey"
		SwellEcom::GeoCountry.create :abbrev => "TM", :name => "Turkmenistan"
		SwellEcom::GeoCountry.create :abbrev => "TC", :name => "Turks and Caicos Islands"
		SwellEcom::GeoCountry.create :abbrev => "TV", :name => "Tuvalu"
		SwellEcom::GeoCountry.create :abbrev => "UG", :name => "Uganda"
		SwellEcom::GeoCountry.create :abbrev => "UA", :name => "Ukraine"
		SwellEcom::GeoCountry.create :abbrev => "AE", :name => "United Arab Emirates"
		SwellEcom::GeoCountry.create :abbrev => "UY", :name => "Uruguay"
		SwellEcom::GeoCountry.create :abbrev => "MIL", :name => "USA Military"
		SwellEcom::GeoCountry.create :abbrev => "UM", :name => "USA Minor Outlying Islands"
		SwellEcom::GeoCountry.create :abbrev => "UZ", :name => "Uzbekistan"
		SwellEcom::GeoCountry.create :abbrev => "VU", :name => "Vanuatu"
		SwellEcom::GeoCountry.create :abbrev => "VA", :name => "Vatican City State"
		SwellEcom::GeoCountry.create :abbrev => "VE", :name => "Venezuela"
		SwellEcom::GeoCountry.create :abbrev => "VN", :name => "Vietnam"
		SwellEcom::GeoCountry.create :abbrev => "VG", :name => "Virgin Islands (British)"
		SwellEcom::GeoCountry.create :abbrev => "VI", :name => "Virgin Islands (USA)"
		SwellEcom::GeoCountry.create :abbrev => "WF", :name => "Wallis and Futuna Islands"
		SwellEcom::GeoCountry.create :abbrev => "EH", :name => "Western Sahara"
		SwellEcom::GeoCountry.create :abbrev => "YE", :name => "Yemen"
		SwellEcom::GeoCountry.create :abbrev => "YU", :name => "Yugoslavia"
		SwellEcom::GeoCountry.create :abbrev => "ZR", :name => "Zaire"
		SwellEcom::GeoCountry.create :abbrev => "ZM", :name => "Zambia"
		SwellEcom::GeoCountry.create :abbrev => "ZW", :name => "Zimbabwe"

		puts "Adding state data"
		usa.geo_states.create :country => 'US', geo_country: usa :name => 'Alabama', :abbrev => 'AL'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Alaska', :abbrev => 'AK'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Arizona', :abbrev => 'AZ'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Arkansas', :abbrev => 'AR'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'California', :abbrev => 'CA'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Colorado', :abbrev => 'CO'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Connecticut', :abbrev => 'CT'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Delaware', :abbrev => 'DE'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'District of Columbia', :abbrev => 'DC'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Florida', :abbrev => 'FL'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Georgia', :abbrev => 'GA'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Hawaii', :abbrev => 'HI'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Idaho', :abbrev => 'ID'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Illinois', :abbrev => 'IL'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Indiana', :abbrev => 'IN'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Iowa', :abbrev => 'IA'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Kansas', :abbrev => 'KS'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Kentucky', :abbrev => 'KY'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Louisiana', :abbrev => 'LA'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Maine', :abbrev => 'ME'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Maryland', :abbrev => 'MD'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Massachusetts', :abbrev => 'MA'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Michigan', :abbrev => 'MI'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Minnesota', :abbrev => 'MN'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Mississippi', :abbrev => 'MS'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Missouri', :abbrev => 'MO'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Montana', :abbrev => 'MT'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Nebraska', :abbrev => 'NE'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Nevada', :abbrev => 'NV'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'New Hampshire', :abbrev => 'NH'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'New Jersey', :abbrev => 'NJ'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'New Mexico', :abbrev => 'NM'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'New York', :abbrev => 'NY'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'North Carolina', :abbrev => 'NC'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'North Dakota', :abbrev => 'ND'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Ohio', :abbrev => 'OH'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Oklahoma', :abbrev => 'OK'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Oregon', :abbrev => 'OR'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Pennsylvania', :abbrev => 'PA'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Rhode Island', :abbrev => 'RI'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'South Carolina', :abbrev => 'SC'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'South Dakota', :abbrev => 'SD'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Tennessee', :abbrev => 'TN'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Texas', :abbrev => 'TX'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Utah', :abbrev => 'UT'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Vermont', :abbrev => 'VT'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Virginia', :abbrev => 'VA'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Washington', :abbrev => 'WA'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'West Virginia', :abbrev => 'WV'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Wisconsin', :abbrev => 'WI'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'Wyoming', :abbrev => 'WY'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'APO', :abbrev => 'AP'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'APO', :abbrev => 'AE'
		usa.geo_states.create :country => 'US', geo_country: usa, :name => 'APO', :abbrev => 'AA'
=begin
		puts "Adding Tax Rates"
		r = SwellEcom::TaxRate.create :geo_state_id => 1 , :rate => 0.04
		r = SwellEcom::TaxRate.create :geo_state_id => 2 , :rate => 0
		r = SwellEcom::TaxRate.create :geo_state_id => 3 , :rate => 0.056
		r = SwellEcom::TaxRate.create :geo_state_id => 4 , :rate => 0.06
		r = SwellEcom::TaxRate.create :geo_state_id => 5 , :rate => 0.0725
		r = SwellEcom::TaxRate.create :geo_state_id => 6 , :rate => 0.029
		r = SwellEcom::TaxRate.create :geo_state_id => 7 , :rate => 0.06
		r = SwellEcom::TaxRate.create :geo_state_id => 8 , :rate => 0
		r = SwellEcom::TaxRate.create :geo_state_id => 9 , :rate => 0.06
		r = SwellEcom::TaxRate.create :geo_state_id => 10 , :rate => 0.06
		r = SwellEcom::TaxRate.create :geo_state_id => 11 , :rate => 0.04

		r = SwellEcom::TaxRate.create :geo_state_id => 12 , :rate => 0.04
		r = SwellEcom::TaxRate.create :geo_state_id => 13 , :rate => 0.06
		r = SwellEcom::TaxRate.create :geo_state_id => 14 , :rate => 0.0625
		r = SwellEcom::TaxRate.create :geo_state_id => 15 , :rate => 0.07
		r = SwellEcom::TaxRate.create :geo_state_id => 16 , :rate => 0.06

		r = SwellEcom::TaxRate.create :geo_state_id => 17 , :rate => 0.053
		r = SwellEcom::TaxRate.create :geo_state_id => 18 , :rate => 0.06
		r = SwellEcom::TaxRate.create :geo_state_id => 19 , :rate => 0.04
		r = SwellEcom::TaxRate.create :geo_state_id => 20 , :rate => 0.05
		r = SwellEcom::TaxRate.create :geo_state_id => 21 , :rate => 0.06

		r = SwellEcom::TaxRate.create :geo_state_id => 22 , :rate => 0.0625
		r = SwellEcom::TaxRate.create :geo_state_id => 23 , :rate => 0.06
		r = SwellEcom::TaxRate.create :geo_state_id => 24 , :rate => 0.06875
		r = SwellEcom::TaxRate.create :geo_state_id => 25 , :rate => 0.07
		r = SwellEcom::TaxRate.create :geo_state_id => 26 , :rate => 0.04225

		r = SwellEcom::TaxRate.create :geo_state_id => 27 , :rate => 0
		r = SwellEcom::TaxRate.create :geo_state_id => 28 , :rate => 0.055
		r = SwellEcom::TaxRate.create :geo_state_id => 29 , :rate => 0.0685
		r = SwellEcom::TaxRate.create :geo_state_id => 30 , :rate => 0
		r = SwellEcom::TaxRate.create :geo_state_id => 31 , :rate => 0.07

		r = SwellEcom::TaxRate.create :geo_state_id => 32 , :rate => 0.05
		r = SwellEcom::TaxRate.create :geo_state_id => 33 , :rate => 0.04
		r = SwellEcom::TaxRate.create :geo_state_id => 34 , :rate => 0.0575
		r = SwellEcom::TaxRate.create :geo_state_id => 35 , :rate => 0.05
		r = SwellEcom::TaxRate.create :geo_state_id => 36 , :rate => 0.055

		r = SwellEcom::TaxRate.create :geo_state_id => 37 , :rate => 0.045
		r = SwellEcom::TaxRate.create :geo_state_id => 38 , :rate => 0
		r = SwellEcom::TaxRate.create :geo_state_id => 39 , :rate => 0.06
		r = SwellEcom::TaxRate.create :geo_state_id => 40 , :rate => 0.07
		r = SwellEcom::TaxRate.create :geo_state_id => 41 , :rate => 0.06

		r = SwellEcom::TaxRate.create :geo_state_id => 42 , :rate => 0.04
		r = SwellEcom::TaxRate.create :geo_state_id => 43 , :rate => 0.07
		r = SwellEcom::TaxRate.create :geo_state_id => 44 , :rate => 0.0625
		r = SwellEcom::TaxRate.create :geo_state_id => 45 , :rate => 0.047
		r = SwellEcom::TaxRate.create :geo_state_id => 46 , :rate => 0.06

		r = SwellEcom::TaxRate.create :geo_state_id => 47 , :rate => 0.05
		r = SwellEcom::TaxRate.create :geo_state_id => 48 , :rate => 0.065
		r = SwellEcom::TaxRate.create :geo_state_id => 49 , :rate => 0.06
		r = SwellEcom::TaxRate.create :geo_state_id => 50 , :rate => 0.05
		r = SwellEcom::TaxRate.create :geo_state_id => 51 , :rate => 0.04
		r = SwellEcom::TaxRate.create :geo_state_id => 52 , :rate => 0
		r = SwellEcom::TaxRate.create :geo_state_id => 53 , :rate => 0
		r = SwellEcom::TaxRate.create :geo_state_id => 54 , :rate => 0
=end
	end
end
