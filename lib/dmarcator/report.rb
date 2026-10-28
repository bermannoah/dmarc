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
    #   The report is not a String, is empty, exceeds {MAX_REPORT_BYTES}, or is
    #   not well-formed XML.
    #
    def initialize(xml)
      self.class.validate_xml!(xml)

      @xml = xml
      @node = Nokogiri::XML(xml) { |config| config.nonet }

      unless @node.errors.empty?
        raise InvalidReport, "invalid DMARC XML report: #{@node.errors.first}"
      end

      @node.remove_namespaces!
    end

    #
    # Streams the records of a DMARC XML report without building a DOM for the
    # whole document.
    #
    # Memory use stays proportional to a single record, at the cost of
    # re-parsing each `record` subtree. Prefer {Report#records} for reports
    # that fit comfortably in memory, and this method for very large ones.
    #
    # @param [String] xml
    #   The raw DMARC XML report.
    #
    # @yieldparam [Record] record
    #   Each record in document order.
    #
    # @return [Enumerator, nil]
    #
    # @raise [InvalidReport]
    #   The report is not a String, is empty, exceeds {MAX_REPORT_BYTES}, or is
    #   not well-formed XML. Well-formedness is only known once the whole
    #   report has been streamed, so records yielded before a malformed tail
    #   are not retracted. libxml2 may emit a diagnostic to stderr for
    #   malformed input; it is not echoed into the exception message.
    #
    def self.each_record(xml, &block)
      return enum_for(:each_record, xml) unless block_given?

      validate_xml!(xml)

      reader = Nokogiri::XML::Reader(xml, nil, nil, Nokogiri::XML::ParseOptions::NONET)

      begin
        reader.each do |node|
          next unless node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
          next unless node.name == 'record' && node.depth == 1

          fragment = node.outer_xml

          if fragment.nil?
            raise InvalidReport, "invalid DMARC XML report: truncated record"
          end

          document = parse_fragment(fragment)
          block.call(Record.new(document.root))
        end
      rescue Nokogiri::XML::SyntaxError => error
        raise InvalidReport, "invalid DMARC XML report: #{error.message}"
      end

      unless reader.errors.empty?
        raise InvalidReport, "invalid DMARC XML report: #{reader.errors.first}"
      end

      nil
    end

    #
    # Parses a single record fragment produced while streaming.
    #
    # @param [String] fragment
    #   The record XML.
    #
    # @return [Nokogiri::XML::Document]
    #
    # @raise [InvalidReport]
    #   The fragment is not well-formed XML.
    #
    # @api private
    #
    def self.parse_fragment(fragment)
      Nokogiri::XML(fragment, nil, nil, Nokogiri::XML::ParseOptions::NONET)
    rescue Nokogiri::XML::SyntaxError => error
      raise InvalidReport, "invalid DMARC XML report: #{error.message}"
    end

    #
    # Validates raw report input before parsing.
    #
    # @param [String] xml
    #   The raw DMARC XML report.
    #
    # @raise [InvalidReport]
    #   The report is not a String, is empty, or exceeds {MAX_REPORT_BYTES}.
    #
    # @api private
    #
    def self.validate_xml!(xml)
      unless xml.is_a?(String)
        raise InvalidReport, "DMARC XML report must be a String, got #{xml.class}"
      end

      if xml.empty?
        raise InvalidReport, "invalid DMARC XML report: empty input"
      end

      if xml.bytesize > MAX_REPORT_BYTES
        raise InvalidReport, "DMARC XML report exceeds maximum size of #{MAX_REPORT_BYTES} bytes"
      end

      nil
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
