# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dmarc/version'

Gem::Specification.new do |gem|
  gem.name          = "dmarc"
  gem.version       = DMARC::VERSION
  gem.license       = 'MIT'
  gem.authors       = ["Davis Gallinghouse"]
  gem.email         = ["davis@trailofbits.com"]
  gem.description   = %q{DMARC Record Parser}
  gem.summary       = %q{DMARC Record Parser}
  gem.homepage      = "https://github.com/trailofbits/dmarc#readme"

  gem.files         = Dir['lib/**/*.rb'] + %w[README.md ChangeLog.md LICENSE.txt]
  gem.test_files    = Dir['spec/**/*']
  gem.require_paths = ["lib"]
  gem.required_ruby_version = '>= 3.0.0'

  gem.add_dependency 'parslet', '>= 1.0.0', '< 3.0.0'
end
