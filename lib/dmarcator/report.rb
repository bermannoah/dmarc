# frozen_string_literal: true

require 'nokogiri'

require_relative 'config'
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
    #
    # @deprecated Use {Config::DEFAULT_MAX_REPORT_BYTES}. Removed in 2.0.
    #
    MAX_REPORT_BYTES = Config::DEFAULT_MAX_REPORT_BYTES

    class << self
      #
      # The maximum accepted report size in bytes.
      #
      # @deprecated Use {DMARCator.configure} with `config.max_report_bytes`.
      #   Removed in 2.0.
      #
      # @return [Integer]
      #
      def max_report_bytes
        DMARCator.config.max_report_bytes
      end

      #
      # Sets the maximum accepted report size in bytes.
      #
      # @deprecated Use {DMARCator.configure} with `config.max_report_bytes`.
      #   Removed in 2.0.
      #
      # @param [Integer, nil] value
      #
      # @raise [ArgumentError]
      #   The value is not a positive Integer or nil.
      #
      def max_report_bytes=(value)
        DMARCator.config.max_report_bytes = value
      end
    end

    #
    # Initializes the report from an XML string.
    #
    # @param [String] xml
    #   The raw DMARC XML report.
    #
    # @raise [InvalidReport]
    #   The report is not a String, exceeds
    #   {Config#max_report_bytes}, or is not well-formed XML.
    #
    def initialize(xml)
      unless xml.is_a?(String)
        raise InvalidReport, "DMARC XML report must be a String, got #{xml.class}"
      end

      @xml = xml

      limit = DMARCator.config.max_report_bytes

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
    # The report version, as published.
    #
    # Returned as a String because versions are opaque identifiers, not
    # numbers to compute with.
    #
    # @return [String, nil]
    #   The version, or `nil` when it is absent or not numeric.
    #
    def version
      return @version if defined?(@version)

      @version = begin
        value = get_text('feedback/version')
        value = value.strip if value

        value if value && value.match?(/\A\d+(?:\.\d+)*\z/)
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
