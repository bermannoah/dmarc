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

        node.element_children.each do |element|
          case element.name
          when 'type'
            self.type ||= element.text
          when 'comment'
            self.comment ||= element.text
          end
        end
      end
    end
  end
end
