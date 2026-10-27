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

        ATTRIBUTES.each do |attr|
          self.public_send("#{attr}=", get_text("feedback/policy_published/#{attr}"))
        end

        self.pct = get_int('feedback/policy_published/pct')
      end
    end
  end
end
