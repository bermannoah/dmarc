# frozen_string_literal: true

require_relative '../xml_helper'

module DMARCator
  class Report
    #
    # Represents the `report_metadata` element of a DMARC XML report.
    #
    class Metadata
      include XmlHelper

      # Attribute names exposed by this class.
      ATTRIBUTES = [
        :org_name, :email, :extra_contact_info, :report_id,
        :begin_at, :end_at, :errors
      ]

      # @!attribute [rw] org_name
      #   @return [String, nil] the reporting organization.
      # @!attribute [rw] email
      #   @return [String, nil] the reporting organization's contact address.
      # @!attribute [rw] extra_contact_info
      #   @return [String, nil] additional contact information.
      # @!attribute [rw] report_id
      #   @return [String, nil] the unique report identifier.
      # @!attribute [rw] begin_at
      #   @return [Time, nil] the start of the reporting interval.
      # @!attribute [rw] end_at
      #   @return [Time, nil] the end of the reporting interval.
      # @!attribute [rw] errors
      #   @return [Array<String>] errors reported by the reporting organization.
      ATTRIBUTES.each { |attribute| attr_accessor(attribute) }

      def initialize(node)
        @node = node
        self.errors = []

        metadata = node.at_xpath('feedback/report_metadata')
        return unless metadata

        metadata.element_children.each do |element|
          case element.name
          when 'org_name'
            self.org_name ||= element.text
          when 'email'
            self.email ||= element.text
          when 'extra_contact_info'
            self.extra_contact_info ||= element.text
          when 'report_id'
            self.report_id ||= element.text
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
            self.begin_at ||= parse_timestamp(element.text)
          when 'end'
            self.end_at ||= parse_timestamp(element.text)
          end
        end
      end
    end
  end
end
