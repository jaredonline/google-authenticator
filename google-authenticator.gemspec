# -*- encoding: utf-8 -*-
require File.expand_path('../lib/google-authenticator-rails/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jared McFarland"]
  gem.email         = ["jared.online@gmail.com"]
  gem.description   = %q{Add the ability to use the Google Authenticator with ActiveRecord.}
  gem.summary       = %q{Add the ability to use the Google Authenticator with ActiveRecord.}
  gem.homepage      = "http://github.com/jaredonline/google-authenticator"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "google-authenticator-rails"
  gem.require_paths = ["lib"]
  gem.version       = Google::Authenticator::Rails::VERSION
  
  gem.add_dependency "activesupport"
  gem.add_dependency "rotp"
  gem.add_dependency "activerecord"
  gem.add_dependency "google-qr"
  
  gem.add_development_dependency "rspec", "~> 2.8.0"
  gem.add_development_dependency "sqlite3"
end
