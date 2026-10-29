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

      # @!attribute [r] type
      #   @return [String] the entry name (`dkim` or `spf`).
      # @!attribute [r] domain
      #   @return [String, nil] the authenticated domain.
      # @!attribute [r] result
      #   @return [String, nil] the authentication result.
      # @!attribute [r] selector
      #   @return [String, nil] the DKIM selector.
      # @!attribute [r] scope
      #   @return [String, nil] the SPF scope.
      ATTRIBUTES.each { |attribute| attr_reader(attribute) }

      def initialize(node)
        @node = node
        @type = node.name

        node.element_children.each do |element|
          case element.name
          when 'domain'
            @domain ||= element.text
          when 'result'
            @result ||= element.text
          when 'selector'
            @selector ||= element.text
          when 'scope'
            @scope ||= element.text
          end
        end
      end
    end
  end
end
