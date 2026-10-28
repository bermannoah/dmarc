# frozen_string_literal: true

require_relative '../xml_helper'

module DMARCator
  class Report
    #
    # Represents an `auth_results` entry (DKIM/SPF) in a DMARC XML report.
    #
    class AuthResult
      include XmlHelper

      ATTRIBUTES = [:type, :domain, :result, :selector, :scope]

      attr_accessor(*ATTRIBUTES)

      def initialize(node)
        @node = node
        self.type = node.name

        node.element_children.each do |element|
          case element.name
          when 'domain'
            self.domain ||= element.text
          when 'result'
            self.result ||= element.text
          when 'selector'
            self.selector ||= element.text
          when 'scope'
            self.scope ||= element.text
          end
        end
      end
    end
  end
end
