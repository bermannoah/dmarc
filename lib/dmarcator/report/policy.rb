# frozen_string_literal: true

require_relative '../xml_helper'

module DMARCator
  class Report
    #
    # Represents the `policy_published` element of a DMARC XML report.
    #
    class Policy
      include XmlHelper

      # Attribute names exposed by this class.
      ATTRIBUTES = [:domain, :adkim, :aspf, :p, :sp, :pct, :fo]

      # @!attribute [rw] domain
      #   @return [String, nil] the domain the policy applies to.
      # @!attribute [rw] adkim
      #   @return [String, nil] the DKIM alignment mode (`r` or `s`).
      # @!attribute [rw] aspf
      #   @return [String, nil] the SPF alignment mode (`r` or `s`).
      # @!attribute [rw] p
      #   @return [String, nil] the requested policy.
      # @!attribute [rw] sp
      #   @return [String, nil] the requested subdomain policy.
      # @!attribute [rw] pct
      #   @return [Integer, nil] the percentage of messages the policy applied to.
      # @!attribute [rw] fo
      #   @return [String, nil] the requested failure-reporting options.
      ATTRIBUTES.each { |attribute| attr_accessor(attribute) }

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
