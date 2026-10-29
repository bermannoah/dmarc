# frozen_string_literal: true

require 'resolv'
require 'rubygems'

require_relative 'resolver'

module DMARCator
  #
  # Resolv gem versions affected by CVE-2026-80212 and CVE-2026-80213.
  #
  VULNERABLE_RESOLV = [
    Gem::Requirement.new('< 0.3.2'),
    Gem::Requirement.new('>= 0.4.0', '< 0.7.2')
  ].freeze

  #
  # DNS query timeouts in seconds, tried in order.
  #
  DNS_TIMEOUTS = [2, 4, 8].freeze

  #
  # Determines the version of the loaded `resolv` gem, if available.
  #
  # @return [String, nil]
  #
  def self.resolv_version
    if defined?(Resolv::VERSION)
      Resolv::VERSION
    elsif (spec = Gem.loaded_specs['resolv'])
      spec.version.to_s
    end
  end

  #
  # Determines whether the loaded `resolv` gem is affected by
  # CVE-2026-80212 or CVE-2026-80213.
  #
  # @return [Boolean]
  #
  def self.vulnerable_resolv?
    version = resolv_version
    return false unless version

    begin
      parsed = Gem::Version.new(version)
    rescue ArgumentError
      # A non-semver version string means we cannot tell; do not warn.
      return false
    end

    VULNERABLE_RESOLV.any? do |requirement|
      requirement.satisfied_by?(parsed)
    end
  end

  #
  # Validates a domain before using it in a DNS query.
  #
  # @param [String] domain
  #   The domain to validate.
  #
  # @return [String]
  #   The validated domain.
  #
  # @raise [ArgumentError]
  #   The domain is not a syntactically valid DNS name.
  #
  def self.validate_domain(domain)
    unless domain.is_a?(String) && !domain.empty? &&
           domain.length <= 248 &&
           !domain.start_with?('.') &&
           !domain.include?('..') &&
           !domain.match?(/[^A-Za-z0-9.-]/) &&
           domain.split('.').all? { |label| label.length <= 63 && !label.start_with?('-') && !label.end_with?('-') }
      raise ArgumentError, "invalid domain: #{domain.inspect}"
    end

    domain
  end

  #
  # Builds the resolver configured by the environment.
  #
  # @return [Resolv::DNS, Resolver::DoH, Resolver::DoT]
  #
  # @raise [ArgumentError]
  #   The configured transport or its settings are invalid.
  #
  # @since 0.6.0
  #
  def self.default_resolver
    Resolver.build
  end

  #
  # Queries a domain for the DMARC record.
  #
  # @param [String] domain
  #   The domain to query DMARC for.
  #
  # @param [Resolv::DNS, Resolver::DoH, Resolver::DoT] resolver
  #   The resolver to use. When omitted, one is built from `DMARCATOR_DNS`;
  #   plaintext resolvers receive {DNS_TIMEOUTS}.
  #
  # @return [String, nil]
  #   The domain's DMARC record or `nil` if none exists.
  #
  # @raise [Resolver::DoH, Resolver::DoT] resolution errors
  #   Encrypted transports raise {ResolutionError} when the lookup fails, so
  #   a transport problem is never reported as a missing record.
  #
  # @api semipublic
  #
  # @since 0.3.0
  #
  def self.query(domain,resolver=default_resolver)
    validate_domain(domain)

    resolver.timeouts = DNS_TIMEOUTS if resolver.respond_to?(:timeouts=)

    host = "_dmarc.#{domain}"

    begin
      records = resolver.getresources(host, Resolv::DNS::Resource::IN::TXT)
    rescue Resolv::ResolvError
      return nil
    end

    # Per RFC 7489 §6.6.3, use the TXT record beginning with "v=DMARC1".
    # If multiple DMARC records exist, treat the domain as having none.
    dmarc_records = records.map { |record| record.strings.join }
                           .select { |text| text.start_with?('v=DMARC1') }

    return dmarc_records.first if dmarc_records.one?
    nil
  end
end

if DMARCator.vulnerable_resolv?
  warn "dmarcator: resolv #{DMARCator.resolv_version} is affected by " \
       "CVE-2026-80212 and CVE-2026-80213; upgrade to resolv >= 0.7.2 " \
       "(or >= 0.3.2 on Ruby 3.3)"
end
