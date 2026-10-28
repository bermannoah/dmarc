# frozen_string_literal: true

require 'nokogiri'

module DMARCator
  #
  # Internal helper for extracting values from parsed DMARC XML reports.
  #
  module XmlHelper
    #
    # Returns the text of the first node matching the XPath expression.
    #
    # @param [String] xpath
    #   The XPath expression to match.
    #
    # @return [String, nil]
    #   The node text, or `nil` if no node matched.
    #
    def get_text(xpath)
      @node.at_xpath(xpath)&.text
    end

    #
    # Returns a Unix timestamp as a `Time`.
    #
    # @param [String] xpath
    #   The XPath expression to match.
    #
    # @return [Time, nil]
    #
    def get_timestamp(xpath)
      parse_timestamp(get_text(xpath))
    end

    #
    # Returns an integer value.
    #
    # @param [String] xpath
    #   The XPath expression to match.
    #
    # @return [Integer, nil]
    #
    def get_int(xpath)
      parse_integer(get_text(xpath))
    end

    #
    # Parses a Unix timestamp from raw element text.
    #
    # @param [String, nil] value
    #   The element text.
    #
    # @return [Time, nil]
    #
    # @api private
    #
    def parse_timestamp(value)
      seconds = parse_integer(value)

      Time.at(seconds) if seconds
    end

    #
    # Parses an integer from raw element text, returning `nil` for values that
    # are not plain decimal digits.
    #
    # @param [String, nil] value
    #   The element text.
    #
    # @return [Integer, nil]
    #
    # @api private
    #
    def parse_integer(value)
      return nil if value.nil? || value.empty?

      digits = value.strip
      return nil unless digits.match?(/\A\d+\z/)

      digits.to_i
    end
  end
end
