$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "swell_ecom/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "swell_ecom"
  s.version     = SwellEcom::VERSION
  s.authors     = ["Gk Parish-Philp", "Michael Ferguson"]
  s.email       = ["gk@playswell.com"]
  s.homepage    = "http://playswell.com"
  s.summary     = "A simple Ecom Solution for Rails."
  s.description = "A simple Ecom Solution for Rails."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.7"
  s.add_dependency "friendly_id", '~> 5.1.0'
  s.add_dependency "haml"

  s.add_development_dependency "sqlite3"
end
