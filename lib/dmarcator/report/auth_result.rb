# frozen_string_literal: true

require_relative '../xml_helper'

module DMARCator
  class Report
    #
    # Represents an `auth_results` entry (DKIM/SPF) in a DMARC XML report.
    #
    class AuthResult
      include XmlHelper

      # Attribute names exposed by this class.
      ATTRIBUTES = [:type, :domain, :result, :selector, :scope]

      # @!attribute [rw] type
      #   @return [String] the entry name (`dkim` or `spf`).
      # @!attribute [rw] domain
      #   @return [String, nil] the authenticated domain.
      # @!attribute [rw] result
      #   @return [String, nil] the authentication result.
      # @!attribute [rw] selector
      #   @return [String, nil] the DKIM selector.
      # @!attribute [rw] scope
      #   @return [String, nil] the SPF scope.
      ATTRIBUTES.each { |attribute| attr_accessor(attribute) }

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
