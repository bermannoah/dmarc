require 'resolv'

module DMARCator
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
           !domain.match?(/[^A-Za-z0-9._-]/) &&
           domain.split('.').all? { |label| label.length <= 63 }
      raise ArgumentError, "invalid domain: #{domain.inspect}"
    end

    domain
  end

  #
  # Queries a domain for the DMARC record.
  #
  # @param [String] domain
  #   The domain to query DMARC for.
  #
  # @param [Resolv::DNS] resolver
  #   The resolver to use.
  #
  # @return [String, nil]
  #   The domain's DMARC record or `nil` if none exists.
  #
  # @api semipublic
  #
  # @since 0.3.0
  #
  def self.query(domain,resolver=Resolv::DNS.new)
    validate_domain(domain)

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
