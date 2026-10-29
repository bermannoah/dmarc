# frozen_string_literal: true

module DMARCator
  #
  # Process-wide defaults.
  #
  # @since 0.11.0
  #
  class Config
    # Default maximum accepted report size in bytes (25 MiB).
    #
    # Parsing a report builds a DOM roughly 13x the input size, so this bounds
    # the memory a hostile report can cost.
    #
    # @since 0.12.0
    #
    DEFAULT_MAX_REPORT_BYTES = 25 * 1024 * 1024

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

    #
    # The maximum accepted report size in bytes.
    #
    # Defaults to {DEFAULT_MAX_REPORT_BYTES}. Lower it to bound memory for
    # reports from untrusted sources.
    #
    # @return [Integer]
    #
    def max_report_bytes
      @max_report_bytes || DEFAULT_MAX_REPORT_BYTES
    end

    #
    # Sets the maximum accepted report size in bytes.
    #
    # @param [Integer, nil] value
    #   A positive number of bytes, or `nil` to restore the default.
    #
    # @raise [ArgumentError]
    #   The value is not a positive Integer or nil.
    #
    def max_report_bytes=(value)
      unless value.nil? || (value.is_a?(Integer) && value.positive?)
        raise ArgumentError,
              "max_report_bytes must be a positive Integer or nil, got #{value.inspect}"
      end

      @max_report_bytes = value
    end
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
