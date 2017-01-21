TaxCloud.configure do |config|
  config.api_login_id = ENV['TAX_CLOUD_API_LOGIN_ID']
  config.api_key = ENV['TAX_CLOUD_API_KEY']
  # config.usps_username = 'your_usps_username' # optional
  # config.open_timeout = 1 # optional
  # config.read_timeout = 1 # optional
end
