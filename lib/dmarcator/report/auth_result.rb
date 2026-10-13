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
        self.domain = get_text('domain')
        self.result = get_text('result')
        self.selector = get_text('selector')
        self.scope = get_text('scope')
      end
    end
  end
end
