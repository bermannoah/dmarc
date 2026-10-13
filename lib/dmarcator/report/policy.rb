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

        self.pct = self.pct && !self.pct.empty? ? self.pct.to_i : nil
      end
    end
  end
end
