# frozen_string_literal: true

require_relative '../xml_helper'

module DMARCator
  class Report
    #
    # Represents the `report_metadata` element of a DMARC XML report.
    #
    class Metadata
      include XmlHelper

      ATTRIBUTES = [
        :org_name, :email, :extra_contact_info, :report_id,
        :begin_at, :end_at, :errors
      ]

      attr_accessor(*ATTRIBUTES)

      def initialize(node)
        @node = node
        self.errors = []

        metadata = node.at_xpath('feedback/report_metadata')
        return unless metadata

        metadata.element_children.each do |element|
          case element.name
          when 'org_name'
            self.org_name = element.text
          when 'email'
            self.email = element.text
          when 'extra_contact_info'
            self.extra_contact_info = element.text
          when 'report_id'
            self.report_id = element.text
          when 'error'
            errors << element.text
          when 'date_range'
            parse_date_range(element)
          end
        end
      end

      private

      def parse_date_range(date_range)
        date_range.element_children.each do |element|
          case element.name
          when 'begin'
            self.begin_at = parse_timestamp(element.text)
          when 'end'
            self.end_at = parse_timestamp(element.text)
          end
        end
      end
    end
  end
end
