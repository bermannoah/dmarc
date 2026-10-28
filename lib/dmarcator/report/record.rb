# frozen_string_literal: true

require_relative '../xml_helper'
require_relative 'auth_result'
require_relative 'reason'

module DMARCator
  class Report
    #
    # Represents a single `record` element of a DMARC XML report.
    #
    class Record
      include XmlHelper

      ATTRIBUTES = [
        :source_ip, :count, :disposition, :dkim, :spf,
        :envelope_to, :envelope_from, :header_from,
        :auth_results, :reasons
      ]

      attr_accessor(*ATTRIBUTES)

      def initialize(node)
        @node = node
        self.reasons = []
        self.auth_results = []

        node.element_children.each do |section|
          case section.name
          when 'row'
            parse_row(section)
          when 'identifiers'
            parse_identifiers(section)
          when 'auth_results'
            parse_auth_results(section)
          end
        end
      end

      private

      def parse_row(row)
        row.element_children.each do |element|
          case element.name
          when 'source_ip'
            self.source_ip ||= element.text
          when 'count'
            self.count ||= parse_integer(element.text)
          when 'policy_evaluated'
            parse_policy_evaluated(element)
          end
        end
      end

      def parse_policy_evaluated(policy_evaluated)
        policy_evaluated.element_children.each do |element|
          case element.name
          when 'disposition'
            self.disposition ||= element.text
          when 'dkim'
            self.dkim ||= element.text
          when 'spf'
            self.spf ||= element.text
          when 'reason'
            reasons << Reason.new(element)
          end
        end
      end

      def parse_identifiers(identifiers)
        identifiers.element_children.each do |element|
          case element.name
          when 'envelope_to'
            self.envelope_to ||= element.text
          when 'envelope_from'
            self.envelope_from ||= element.text
          when 'header_from'
            self.header_from ||= element.text
          end
        end
      end

      def parse_auth_results(auth_results)
        auth_results.element_children.each do |element|
          self.auth_results << AuthResult.new(element)
        end
      end
    end
  end
end
