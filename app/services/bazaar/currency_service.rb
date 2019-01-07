module Bazaar
	class CurrencyService

		MARKETPLACE_CURRENCIES_CONVERSION_RATE = {
			'USD' => 1.0,
			'CAD' => 1.33,
			'GBP'	=> 0.78,
			'EUR' => 0.89,
			'BRL' => 3.88,
			'INR' => 70.89,
			'CNY' => 6.95,
			'JPY' => 113.73,
			'AUD' => 1.39,
		}

		def get_usd_currency_rate( currency )
			MARKETPLACE_CURRENCIES_CONVERSION_RATE[currency]
		end

		def convert( value, from_currency, to_currency, options = {} )
			usd_value = 1 / get_usd_currency_rate( from_currency ) * value.to_f
			to_value = get_usd_currency_rate( to_currency ) * value.to_f
			to_value
		end

	end
end
