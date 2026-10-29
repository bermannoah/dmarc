require 'spec_helper'
require 'dmarcator'

RSpec.describe DMARCator::Config do
  after { DMARCator.reset_configuration! }

  describe '.config' do
    it 'returns a Config' do
      expect(DMARCator.config).to be_a(described_class)
    end

    it 'is memoized' do
      expect(DMARCator.config).to be(DMARCator.config)
    end
  end

  describe '.configure' do
    it 'yields the configuration and returns it' do
      yielded = nil

      result = DMARCator.configure { |config| yielded = config }

      expect(yielded).to be(DMARCator.config)
      expect(result).to be(DMARCator.config)
    end

    it 'returns the configuration without a block' do
      expect(DMARCator.configure).to be(DMARCator.config)
    end
  end

  describe '.default_resolver' do
    it 'uses the configured resolver object' do
      resolver = double('resolver')
      DMARCator.configure { |config| config.resolver = resolver }

      expect(DMARCator.default_resolver).to be(resolver)
    end

    it 'calls a configured callable for each lookup' do
      resolvers = [double('one'), double('two')]
      calls = 0
      DMARCator.configure { |config| config.resolver = -> { calls += 1; resolvers[calls - 1] } }

      expect(DMARCator.default_resolver).to be(resolvers[0])
      expect(DMARCator.default_resolver).to be(resolvers[1])
    end

    it 'takes precedence over the environment' do
      resolver = double('resolver')
      DMARCator.configure { |config| config.resolver = resolver }

      allow(DMARCator::Resolver).to receive(:build)

      expect(DMARCator.default_resolver).to be(resolver)
      expect(DMARCator::Resolver).not_to have_received(:build)
    end

    it 'falls back to the environment when unconfigured' do
      allow(DMARCator::Resolver).to receive(:build).and_return(:from_env)

      expect(DMARCator.default_resolver).to eq(:from_env)
    end
  end

  describe '.reset_configuration!' do
    it 'discards configured values' do
      DMARCator.configure { |config| config.resolver = double('resolver') }

      DMARCator.reset_configuration!

      expect(DMARCator.config.resolver).to be_nil
    end
  end
end
