# frozen_string_literal: true

require_relative '../xml_helper'

module DMARCator
  class Report
    #
    # Represents a `reason` element of a DMARC XML report record.
    #
    class Reason
      include XmlHelper

      ATTRIBUTES = [:type, :comment]

      attr_accessor(*ATTRIBUTES)

      def initialize(node)
        @node = node
        self.type = get_text('type')
        self.comment = get_text('comment')
      end
    end
  end
end
