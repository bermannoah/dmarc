# frozen_string_literal: true

module DMARCator
  #
  # Base class for every error raised by this library.
  #
  # Rescuing this catches parse failures, report failures and DNS lookup
  # failures alike.
  #
  # @since 0.10.0
  #
  class Error < StandardError
  end

  #
  # Raised when a DMARC record cannot be parsed.
  #
  # @since 0.2.0
  #
  class InvalidRecord < Error
  end

  #
  # Raised when a DMARC XML report cannot be parsed.
  #
  # @since 0.3.0
  #
  class InvalidReport < Error
  end

  #
  # Raised when a DNS transport fails to return a usable answer.
  #
  # This is deliberately distinct from a missing record: a failed lookup must
  # not be mistaken for a domain without a DMARC policy.
  #
  # @since 0.6.0
  #
  class ResolutionError < Error
  end
end
