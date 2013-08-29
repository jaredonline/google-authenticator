# -*- encoding: utf-8 -*-
require File.expand_path('../lib/google-authenticator-rails/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Hector Bustillos"]
  gem.email         = ["hecbuma@gmail.com"]
  gem.description   = %q{This gem is a fork of Jared McFarland's }
  gem.summary       = %q{You can find the original here http://github.com/jaredonline/google-authenticator.}
  gem.homepage      = "http://github.com/hecbuma/google-authenticator"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "google-authenticator-rails"
  gem.require_paths = ["lib"]
  gem.version       = Google::Authenticator::Rails::VERSION

  gem.add_dependency "rotp"
  gem.add_dependency "activerecord"
  gem.add_dependency "google-qr"
  gem.add_dependency "actionpack"

  gem.add_development_dependency "rspec", "~> 2.8.0"
  gem.add_development_dependency "sqlite3"
end
