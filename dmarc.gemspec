# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dmarcator/version'

Gem::Specification.new do |gem|
  gem.name          = "dmarcator-gem"
  gem.version       = DMARCator::VERSION
  gem.license       = 'MIT'
  gem.authors       = ["Noah Berman", "Davis Gallinghouse"]
  gem.email         = ["noah@noahberman.org", "davis@trailofbits.com"]
  gem.description   = "A hardened DMARC record parser and query client, forked from the Trail of Bits 'dmarc' gem."
  gem.summary       = "DMARC record parser and query client"
  gem.homepage      = "https://github.com/bermannoah/dmarc"

  gem.metadata = {
    "source_code_uri"   => "https://github.com/bermannoah/dmarc",
    "bug_tracker_uri"   => "https://github.com/bermannoah/dmarc/issues",
    "rubygems_mfa_required" => "true"
  }

  gem.files         = Dir['lib/**/*.rb'] + %w[README.md ChangeLog.md LICENSE.txt]
  gem.test_files    = Dir['spec/**/*']
  gem.require_paths = ["lib"]
  gem.required_ruby_version = '>= 3.0.0'

  gem.add_dependency 'parslet', '>= 1.0.0', '< 3.0.0'
end
