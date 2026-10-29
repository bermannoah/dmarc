# frozen_string_literal: true

require 'parslet'

module DMARCator
  #
  # Raised when a DMARC record cannot be parsed.
  #
  # @since 0.2.0
  #
  class InvalidRecord < Parslet::ParseFailed
  end

  #
  # Raised when a DMARC XML report cannot be parsed.
  #
  class InvalidReport < StandardError
  end

  #
  # Raised when an encrypted DNS transport fails to return a usable answer.
  #
  # This is deliberately distinct from a missing record: a failed lookup must
  # not be mistaken for a domain without a DMARC policy.
  #
  # @since 0.6.0
  #
  class ResolutionError < StandardError
  end
end
