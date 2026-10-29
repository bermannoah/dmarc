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
  # Applied when the library builds a plaintext resolver. Timeouts on an
  # injected resolver are left alone.
  #
  DNS_TIMEOUTS = [2, 4, 8].freeze

  #
  # The maximum length of a textual DNS name, in octets.
  #
  # @since 0.8.0
  #
  MAX_TXT_NAME_LENGTH = 253

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
  # Rejects underscores and reserves room for the `_dmarc.` prefix, so this is
  # the validator for registrable domains rather than arbitrary DNS names.
  # Use {validate_txt_name} for service labels.
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
  # Validates an arbitrary DNS name used for a TXT lookup.
  #
  # Unlike {validate_domain}, service labels such as `_dmarc` and `_domainkey`
  # are allowed, so names may contain underscores. Length and label limits are
  # still enforced so hostile input cannot reach the resolver unbounded.
  #
  # @param [String] name
  #   The DNS name to validate.
  #
  # @return [String]
  #   The validated name.
  #
  # @raise [ArgumentError]
  #   The name is not a syntactically valid DNS name.
  #
  # @since 0.8.0
  #
  def self.validate_txt_name(name)
    unless name.is_a?(String) && !name.empty? &&
           name.length <= MAX_TXT_NAME_LENGTH &&
           !name.start_with?('.') &&
           !name.include?('..') &&
           name.match?(/\A[A-Za-z0-9._-]+\z/) &&
           name.split('.').all? { |label| label.length <= 63 && !label.start_with?('-') && !label.end_with?('-') }
      raise ArgumentError, "invalid TXT name: #{name.inspect}"
    end

    name
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
  # Looks up every TXT record published at a DNS name.
  #
  # Records are returned exactly as published: unfiltered, in response order,
  # and with multi-chunk records joined. Interpreting them (SPF, DKIM, DMARC,
  # domain verification) is left to the caller. Use this when the individual
  # records matter, for example to detect that a domain publishes more than
  # one DMARC record.
  #
  # @param [String] name
  #   The DNS name to look up, such as `example.com`, `_dmarc.example.com`, or
  #   `s1._domainkey.example.com`.
  #
  # @param [Resolv::DNS, Resolver::DoH, Resolver::DoT] resolver
  #   The resolver to use. When omitted, one is built from `DMARCATOR_DNS`.
  #   An injected resolver keeps its own configuration.
  #
  # @return [Array<String>]
  #   The TXT records, or an empty array when the name has none. NXDOMAIN and
  #   NODATA are indistinguishable here.
  #
  # @raise [ResolutionError]
  #   The lookup failed. A failure is never reported as an empty result, so a
  #   blocked or degraded resolver cannot be mistaken for an absent record.
  #
  # @raise [ArgumentError]
  #   The name is not a syntactically valid DNS name.
  #
  # @note Names must be ASCII: pass punycode (A-labels) rather than Unicode.
  #
  # @since 0.8.0
  #
  def self.txt(name, resolver: default_resolver)
    lookup_txt(validate_txt_name(name), resolver: resolver)
  end

  #
  # Looks up the DMARC record text published for a domain.
  #
  # This is the lowest-cost DMARC path: one TXT lookup and no parsing. Use it
  # for bulk scans, and call {Record.parse} only on records you care about.
  #
  # @param [String] domain
  #   The domain to look up DMARC for.
  #
  # @param [Resolv::DNS, Resolver::DoH, Resolver::DoT] resolver
  #   The resolver to use. When omitted, one is built from `DMARCATOR_DNS`.
  #
  # @return [String, nil]
  #   The DMARC record text, or `nil` when the domain publishes none or
  #   publishes more than one (per RFC 7489 §6.6.3). Use {txt} to see every
  #   record, including duplicates.
  #
  # @raise [ResolutionError]
  #   The lookup failed.
  #
  # @raise [ArgumentError]
  #   The domain is not a syntactically valid DNS name.
  #
  # @since 0.8.0
  #
  def self.dmarc(domain, resolver: default_resolver)
    name = "_dmarc.#{validate_domain(domain)}"

    # Per RFC 7489 §6.6.3, use the TXT record beginning with "v=DMARC1".
    # If multiple DMARC records exist, treat the domain as having none.
    dmarc_records = lookup_txt(name, resolver: resolver).select do |text|
      text.start_with?('v=DMARC1')
    end

    dmarc_records.first if dmarc_records.one?
  end

  #
  # @deprecated Use {dmarc}, which names what it returns. Kept for
  #   compatibility; it will be removed in a future release.
  #
  # @see dmarc
  #
  def self.query(domain,resolver=default_resolver)
    dmarc(domain, resolver: resolver)
  end

  #
  # Looks up the TXT records at an already-validated name.
  #
  # Shared by {txt} and {dmarc} so both use one transport path.
  #
  # @param [String] name
  #
  # @param [Resolv::DNS, Resolver::DoH, Resolver::DoT] resolver
  #
  # @return [Array<String>]
  #
  # @raise [ResolutionError]
  #
  # @api private
  #
  def self.lookup_txt(name, resolver:)
    # Resolv returns an empty result for NXDOMAIN and raises for timeouts and
    # other failures, so any exception here is a transport failure, not an
    # absent record.
    begin
      records = resolver.getresources(name, Resolv::DNS::Resource::IN::TXT)
    rescue Resolv::ResolvError => error
      raise ResolutionError, "DNS TXT lookup failed for #{name}: #{error.message}"
    end

    records.map { |record| record.strings.join }
  end
  private_class_method :lookup_txt
end

if DMARCator.vulnerable_resolv?
  warn "dmarcator: resolv #{DMARCator.resolv_version} is affected by " \
       "CVE-2026-80212 and CVE-2026-80213; upgrade to resolv >= 0.7.2 " \
       "(or >= 0.3.2 on Ruby 3.3)"
end
