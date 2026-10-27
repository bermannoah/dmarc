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
  # Nokogiri's default parse options are used, which do not resolve external
  # entities or fetch network resources; treat report XML as untrusted input.
  #
  class Report
    include XmlHelper

    #
    # Initializes the report from an XML string.
    #
    # @param [String] xml
    #   The raw DMARC XML report.
    #
    def initialize(xml)
      @xml = xml
      @node = Nokogiri::XML(xml)

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
