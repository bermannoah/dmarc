# frozen_string_literal: true

require_relative '../xml_helper'

module DMARCator
  class Report
    #
    # Represents the `policy_published` element of a DMARC XML report.
    #
    class Policy
      include XmlHelper

      ATTRIBUTES = [:domain, :adkim, :aspf, :p, :sp, :pct, :fo]

      attr_accessor(*ATTRIBUTES)

      def initialize(node)
        @node = node

        policy = node.at_xpath('feedback/policy_published')
        return unless policy

        policy.element_children.each do |element|
          case element.name
          when 'pct'
            self.pct ||= parse_integer(element.text)
          when 'domain'
            self.domain ||= element.text
          when 'adkim'
            self.adkim ||= element.text
          when 'aspf'
            self.aspf ||= element.text
          when 'p'
            self.p ||= element.text
          when 'sp'
            self.sp ||= element.text
          when 'fo'
            self.fo ||= element.text
          end
        end
      end
    end
  end
end
