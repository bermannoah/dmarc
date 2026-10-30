# frozen_string_literal: true

require 'dmarcator/exceptions'
require 'dmarcator/query'
require 'dmarcator/record'
require 'dmarcator/internal/parser'
require 'dmarcator/report'
require 'dmarcator/version'

#
# Parses, queries, and validates DMARC records and aggregates.
#
# Use {DMARCator::Record} for `_dmarc.<domain>` TXT records, {DMARCator::Report}
# for aggregate/forensic XML reports, and {DMARCator::Resolver} to choose the
# DNS transport (plaintext, DNS over HTTPS, or DNS over TLS).
#
# @see https://www.rfc-editor.org/rfc/rfc7489
#
module DMARCator
end
