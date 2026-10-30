# frozen_string_literal: true

require 'resolv'

require_relative 'exceptions'
require_relative 'resolver/encrypted'
require_relative 'resolver/plain'
require_relative 'resolver/doh'
require_relative 'resolver/dot'

module DMARCator
  #
  # Selects the DNS transport used for DMARC lookups.
  #
  # The transport is chosen with the `DMARCATOR_DNS` environment variable, or
  # explicitly via {.build}:
  #
  #   DMARCATOR_DNS=plaintext          # default: TCP (Resolver::Plain)
  #   DMARCATOR_DNS=doh                # requires DMARCATOR_DOH_URL
  #   DMARCATOR_DNS=dot                # requires DMARCATOR_DOT_SERVER
  #
  # Encrypted transports fail closed: a transport failure raises
  # {ResolutionError} instead of being reported as "no DMARC record".
  #
  # @since 0.6.0
  #
  module Resolver
    # Supported transport names.
    MODES = %w[plaintext doh dot].freeze

    # Transport used when `DMARCATOR_DNS` is unset.
    DEFAULT_MODE = 'plaintext'

    #
    # Reads the configured transport name.
    #
    # @param [Hash] env
    #
    # @return [String]
    #
    def self.mode(env = ENV)
      value = env['DMARCATOR_DNS']

      value.nil? || value.empty? ? DEFAULT_MODE : value.to_s.strip.downcase
    end

    #
    # Builds the configured resolver.
    #
    # @param [String, nil] mode
    #   Overrides the `DMARCATOR_DNS` environment variable.
    #
    # @param [Hash] env
    #
    # @return [Resolv::DNS, DoH, DoT]
    #
    # @raise [ArgumentError]
    #   The mode or its required settings are invalid.
    #
    def self.build(mode: nil, env: ENV)
      name = (mode || self.mode(env)).to_s.strip.downcase

      case name
      when 'plaintext'
        Plain.from_env(env)
      when 'doh'
        DoH.from_env(env)
      when 'dot'
        DoT.from_env(env)
      else
        raise ArgumentError,
              "unknown DMARCATOR_DNS value: #{name.inspect} " \
              "(expected one of #{MODES.join(', ')})"
      end
    end
  end
end
