# frozen_string_literal: true

module DMARCator
  #
  # Process-wide defaults.
  #
  # @since 0.11.0
  #
  class Config
    #
    # The default resolver used when a lookup is not given one.
    #
    # Either a resolver ({Resolv::DNS}, {Resolver::DoH}, {Resolver::DoT}) or a
    # callable returning one. Prefer a callable in threaded applications: a
    # resolver object is shared by every thread, and `Resolv::DNS` does not
    # serialise concurrent lookups.
    #
    # @return [Object, #call, nil]
    #
    attr_accessor :resolver
  end

  #
  # The process-wide configuration.
  #
  # @return [Config]
  #
  # @since 0.11.0
  #
  def self.config
    @config ||= Config.new
  end

  #
  # Configures process-wide defaults.
  #
  #   DMARCator.configure do |config|
  #     config.resolver = -> { Resolv::DNS.new }
  #   end
  #
  # When set, a configured resolver takes precedence over `DMARCATOR_DNS` and
  # is used by {txt}, {txt_records}, {dmarc} and {Record.lookup} whenever no
  # resolver is passed explicitly.
  #
  # @yieldparam [Config] config
  #
  # @return [Config]
  #
  # @since 0.11.0
  #
  def self.configure
    yield config if block_given?
    config
  end

  #
  # Discards any configured defaults.
  #
  # @return [Config]
  #
  # @since 0.11.0
  #
  def self.reset_configuration!
    @config = Config.new
  end
end
