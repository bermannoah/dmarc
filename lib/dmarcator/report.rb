# frozen_string_literal: true

require 'nokogiri'
require 'bigdecimal'
require 'bigdecimal/util'

require_relative 'xml_helper'
require_relative 'exceptions'
require_relative 'report/metadata'
require_relative 'report/policy'
require_relative 'report/record'

module DMARCator
  #
  # Represents a parsed DMARC aggregate/forensic XML report.
  #
  # Parsing disables network access (NONET) so external entities are never
  # resolved or fetched; treat report XML as untrusted input.
  #
  class Report
    include XmlHelper

    # Maximum accepted report size in bytes (25 MiB).
    MAX_REPORT_BYTES = 25 * 1024 * 1024

    #
    # Initializes the report from an XML string.
    #
    # @param [String] xml
    #   The raw DMARC XML report.
    #
    # @raise [InvalidReport]
    #   The report is not a String, exceeds {MAX_REPORT_BYTES}, or is not
    #   well-formed XML.
    #
    def initialize(xml)
      unless xml.is_a?(String)
        raise InvalidReport, "DMARC XML report must be a String, got #{xml.class}"
      end

      @xml = xml

      if xml.bytesize > MAX_REPORT_BYTES
        raise InvalidReport, "DMARC XML report exceeds maximum size of #{MAX_REPORT_BYTES} bytes"
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
      @version ||= begin
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
    # @return [Array<Report::Record>]
    #
    def records
      @records ||= @node.xpath('feedback/record').map do |node|
        Record.new(node)
      end
    end
  end
end
