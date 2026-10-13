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
      value = get_text(xpath)
      value && !value.empty? ? Time.at(value.to_i) : nil
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
      value = get_text(xpath)
      value && !value.empty? ? value.to_i : nil
    end
  end
end
