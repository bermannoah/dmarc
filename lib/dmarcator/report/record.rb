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
        :envelope_to, :envelope_from, :header_from
      ]

      attr_accessor(*ATTRIBUTES)
      attr_writer :auth_results, :reasons

      def initialize(node)
        @node = node
        @reason_nodes = []
        @auth_result_nodes = []

        node.element_children.each do |section|
          case section.name
          when 'row'
            parse_row(section)
          when 'identifiers'
            parse_identifiers(section)
          when 'auth_results'
            collect_auth_results(section)
          end
        end
      end

      #
      # The record's `reason` elements.
      #
      # @return [Array<Reason>]
      #
      def reasons
        return @reasons if defined?(@reasons)

        @reasons = @reason_nodes.map { |reason_node| Reason.new(reason_node) }
      end

      #
      # The record's `auth_results` entries.
      #
      # @return [Array<AuthResult>]
      #
      def auth_results
        return @auth_results if defined?(@auth_results)

        @auth_results = @auth_result_nodes.map do |auth_result_node|
          AuthResult.new(auth_result_node)
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
            @reason_nodes << element
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

      def collect_auth_results(auth_results)
        auth_results.element_children.each do |element|
          @auth_result_nodes << element
        end
      end
    end
  end
end
