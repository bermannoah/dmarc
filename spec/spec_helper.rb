require 'simplecov'
SimpleCov.start

require 'rspec'
require 'dmarcator'

include DMARCator

RSpec.configure do |specs|
  specs.filter_run_excluding :gauntlet
end
