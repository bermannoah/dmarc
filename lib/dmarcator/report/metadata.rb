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
        self.org_name = get_text('feedback/report_metadata/org_name')
        self.email = get_text('feedback/report_metadata/email')
        self.extra_contact_info = get_text('feedback/report_metadata/extra_contact_info')
        self.report_id = get_text('feedback/report_metadata/report_id')
        self.begin_at = get_timestamp('feedback/report_metadata/date_range/begin')
        self.end_at = get_timestamp('feedback/report_metadata/date_range/end')
        self.errors = @node.xpath('feedback/report_metadata/error').map(&:text)
      end
    end
  end
end
