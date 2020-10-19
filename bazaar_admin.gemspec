$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "bazaar_admin/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "bazaar"
  s.version     = BazaarAdmin::VERSION
  s.authors     = ["Gk Parish-Philp", "Michael Ferguson"]
  s.email       = ["gk@groundswellenterprises.com"]
  s.homepage    = "http://www.groundswellenterprises.com"
  s.summary     = "A simple Ecom Solution for Rails."
  s.description = "A simple Ecom Solution for Rails."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  # s.test_files = Dir["test/**/*"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency 'jbuilder'
  s.add_dependency "pulitzer"
  s.add_dependency "swell_id"
  # s.add_dependency 'tax_cloud'
  # s.add_dependency 'stripe' #, :git => 'https://github.com/stripe/stripe-ruby'
  s.add_dependency 'bazaar_core'# , :git => 'https://github.com/MeisterMichael/bazaar.git', :branch => 'bazaar-core'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'rails-controller-testing'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'factory_bot_rails'
  # s.add_development_dependency 'taxjar-ruby'
  # s.add_dependency 'authorizenet'
  s.add_dependency 'rest-client'
  s.add_dependency 'credit_card_validations'
  # s.add_dependency 'paypal-sdk-rest'
  s.add_development_dependency "sqlite3"
end
