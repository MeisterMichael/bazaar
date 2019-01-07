
namespace :bazaar do

	task cache_currnecy_rates: :environment do
		require 'money/bank/open_exchange_rates_bank'

		# Memory store per default; for others just pass as argument a class like
		# explained in https://github.com/RubyMoney/money#exchange-rate-stores
		oxr = Money::Bank::OpenExchangeRatesBank.new
		oxr.app_id = ENV['OPEN_EXCHANGE_RATES_APP_ID']
		rates = oxr.update_rates

		timestamp = oxr.rates_timestamp.to_f

		rates.each do |currency_code,rate|
			currency = Bazaar::Currency.create_with( name: currency_code ).find_or_create_by( code: currency_code )

			currency.history[timestamp] = rate
			currency.usd_conversion_rate = rate
			currency.save

		end

	end
end
