# frozen_string_literal: true

require 'nokogiri'
require 'bigdecimal'
require 'bigdecimal/util'

require_relative 'xml_helper'
require_relative 'exceptions'
require_relative 'report/metadata'
require_relative 'report/policy'
require_relative 'report/row'

module DMARCator
  #
  # Represents a parsed DMARC aggregate/forensic XML report.
  #
  # Parsing disables network access (NONET) so external entities are never
  # resolved or fetched; treat report XML as untrusted input.
  #
  class Report
    include XmlHelper

    # Default maximum accepted report size in bytes (25 MiB).
    MAX_REPORT_BYTES = 25 * 1024 * 1024

    class << self
      #
      # The maximum accepted report size in bytes.
      #
      # Defaults to {MAX_REPORT_BYTES}. Parsing a report builds a DOM that is
      # roughly 13x the input size, so lower this to bound memory for reports
      # from untrusted sources.
      #
      # @return [Integer]
      #
      attr_writer :max_report_bytes

      def max_report_bytes
        @max_report_bytes || MAX_REPORT_BYTES
      end
    end

    #
    # Initializes the report from an XML string.
    #
    # @param [String] xml
    #   The raw DMARC XML report.
    #
    # @raise [InvalidReport]
    #   The report is not a String, exceeds {.max_report_bytes}, or is not
    #   well-formed XML.
    #
    def initialize(xml)
      unless xml.is_a?(String)
        raise InvalidReport, "DMARC XML report must be a String, got #{xml.class}"
      end

      @xml = xml

      limit = self.class.max_report_bytes

      if xml.bytesize > limit
        raise InvalidReport, "DMARC XML report exceeds maximum size of #{limit} bytes"
      end

      @node = Nokogiri::XML(xml) { |config| config.nonet }

      unless @node.errors.empty?
        raise InvalidReport, "invalid DMARC XML report: #{@node.errors.first}"
      end

      @node.remove_namespaces!
    end

    #
    # The report version.
    #
    # @return [BigDecimal, nil]
    #
    def version
      return @version if defined?(@version)

      @version = begin
        value = get_text('feedback/version')

        if value && !value.empty?
          begin
            BigDecimal(value)
          rescue ArgumentError
            nil
          end
        end
      end
    end

    #
    # The report metadata.
    #
    # @return [Report::Metadata]
    #
    def metadata
      @metadata ||= Metadata.new(@node)
    end

    #
    # The published DMARC policy.
    #
    # @return [Report::Policy]
    #
    def policy
      @policy ||= Policy.new(@node)
    end

    #
    # The report records.
    #
    # @return [Array<Report::Row>]
    #
    def records
      @records ||= @node.xpath('feedback/record').map do |node|
        Row.new(node)
      end
    end
  end
end
