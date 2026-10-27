require 'parslet'

module DMARCator
  class InvalidRecord < Parslet::ParseFailed
  end

  #
  # Raised when a DMARC XML report cannot be parsed.
  #
  class InvalidReport < StandardError
  end
end
