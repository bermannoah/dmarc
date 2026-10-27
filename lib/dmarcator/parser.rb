# frozen_string_literal: true

require 'dmarcator/exceptions'
require 'dmarcator/uri'

require 'parslet'
require 'uri'

module DMARCator
  #
  # DMARC parser.
  #
  # @see https://tools.ietf.org/html/rfc7489#section-6.4
  #
  class Parser < Parslet::Parser

    root :dmarc_record

    rule(:dmarc_record) do
      dmarc_version.repeat(1,1) >>
      (dmarc_sep >> dmarc_tag).repeat >>
      dmarc_sep.maybe >>
      wsp?.maybe
    end

    rule(:dmarc_sep) { wsp? >> str(';') >> wsp? }

    rule(:dmarc_version) do
      str('v') >> wsp? >>
      str('=') >> wsp? >>
      str('DMARC1').as(:v)
    end

    rule(:dmarc_tag) do
      dmarc_request   |
      dmarc_srequest  |
      dmarc_auri      |
      dmarc_furi      |
      dmarc_adkim     |
      dmarc_aspf      |
      dmarc_ainterval |
      dmarc_fo        |
      dmarc_rfmt      |
      dmarc_percent   |
      unknown_tag
    end

    def self.tag_rule(name,tag,&block)
      rule(:"dmarc_#{name}") do
        (
          str(tag) >> wsp? >> str('=') >> wsp? >>
          instance_eval(&block).as(tag.to_sym)
        ) |
        (
          str(tag) >> wsp? >> str('=') >> wsp? >>
          match["^; \t"].repeat(1)
        ).as(:invalid_tag)
      end
    end

    tag_rule(:request,'p') do
      str('none') | str('quarantine') | str('reject')
    end

    tag_rule(:srequest,'sp') do
      str('none') | str('quarantine') | str('reject')
    end

    tag_rule(:auri, 'rua') do
      dmarc_uri >> (uri_list_sep.present? >> uri_list_sep).repeat >> (wsp? >> str(',')).absent?
    end

    tag_rule(:ainterval,'ri') { digit.repeat(1, 10) >> digit.absent? }

    tag_rule(:furi,'ruf') do
      dmarc_uri >> (uri_list_sep.present? >> uri_list_sep).repeat >> (wsp? >> str(',')).absent?
    end

    tag_rule(:fo,'fo') do
      fo_opt >> (wsp? >> str(':') >> wsp? >> fo_opt).repeat
    end

    rule(:fo_opt) { match['01ds'].as(:fo_opt) }

    tag_rule(:rfmt,'rf') { str('afrf') | str('iodef') }

    tag_rule(:percent,'pct') { digit.repeat(1,3) >> digit.absent? }

    tag_rule(:adkim, 'adkim') { match['rs'] }
    tag_rule(:aspf, 'aspf')   { match['rs'] }

    rule(:unknown_tag) { match["^; \t"].repeat(1).as(:unknown_tag) }

    rule(:dmarc_uri) do
      mailto_uri.as(:uri) >> (
        str('!') >> digit.repeat(1, 10).as(:size) >> digit.absent? >> (
          match['kmgt']
        ).as(:unit).maybe
      ).maybe >> str('!').absent?
    end

    rule(:uri_list_sep) { wsp? >> str(',') >> wsp? >> dmarc_uri }

    rule(:mailto_uri) do
      match['mM'] >> match['aA'] >> match['iI'] >> match['lL'] >> match['tT'] >> match['oO'] >>
      str(':') >> mailto_address
    end

    rule(:mailto_address) do
      mailto_local >> str('@') >> mailto_domain
    end

    rule(:mailto_local)  { mailto_char.repeat(1) }
    rule(:mailto_domain) { mailto_char.repeat(1) }
    rule(:mailto_char)   { match["^;,! \t@"] }

    rule(:digit) { match('[0-9]') }
    rule(:wsp) { str(' ') | str("\t") }
    rule(:wsp?) { wsp.repeat }

    class Transform < Parslet::Transform

      rule(fo_opt: simple(:fo_opt)) { fo_opt }
      rule(fo: simple(:fo_opt)) { {fo: [fo_opt]} }

      rule(v: simple(:version)) { {v: version.to_sym} }
      rule(p:  simple(:p))  { {p:  p.to_sym } }
      rule(sp: simple(:sp)) { {sp: sp.to_sym} }
      rule(rf: simple(:rf)) { {rf: rf.to_sym} }
      rule(adkim: simple(:adkim)) { {adkim: adkim.to_sym} }
      rule(aspf:  simple(:aspf))  { {aspf: aspf.to_sym} }

      rule(pct: simple(:pct)) { {pct: pct.to_i} }
      rule(ri:  simple(:ri))  { {ri:  ri.to_i}  }

      rule(uri: simple(:uri), size: simple(:size), unit: simple(:unit)) do
        Uri.new(
          Transform.parse_uri(uri),
          size.to_i,
          unit.to_sym
        )
      end
      rule(uri: simple(:uri), size: simple(:size)) do
        Uri.new(
          Transform.parse_uri(uri),
          size.to_i
        )
      end
      rule(uri: simple(:uri)) { Uri.new(Transform.parse_uri(uri)) }
      rule(rua: subtree(:uris)) { {rua: Array(uris)} }
      rule(ruf: subtree(:uris)) { {ruf: Array(uris)} }

      MAX_ERROR_MESSAGE_LENGTH = 300

      def self.parse_uri(value)
        uri = value.to_s

        begin
          parsed = URI.parse(uri)
        rescue URI::Error => error
          raise InvalidRecord, truncate(error.message)
        end

        unless parsed.is_a?(URI::MailTo)
          raise InvalidRecord, "invalid DMARC report URI (expected mailto): #{truncate(uri)}"
        end

        parsed
      end

      def self.truncate(message)
        message = message.to_s

        if message.length > MAX_ERROR_MESSAGE_LENGTH
          message[0, MAX_ERROR_MESSAGE_LENGTH] + "..."
        else
          message
        end
      end

    end

    #
    # Parses a DMARC record.
    #
    # @param [String] record
    #   The raw DMARC record to parse.
    #
    # @param [Boolean] strict (false)
    #   When `true`, raise on unknown tags or invalid tag values instead of
    #   silently ignoring them.
    #
    # @return [Hash{Symbol => Object}]
    #   The Hash of tags within the record.
    #
    # @raise [InvalidRecord]
    #   The record is malformed, or (in strict mode) contains an unknown tag
    #   or invalid tag value.
    #
    def self.parse(record, strict: false)
      tree = new.parse(record)

      if strict
        tree.each do |node|
          next unless ignored?(node)

          if node.key?(:unknown_tag)
            raise InvalidRecord, "unknown DMARC tag: #{Transform.truncate(node[:unknown_tag].to_s).inspect}"
          else
            raise InvalidRecord, "invalid DMARC tag value: #{Transform.truncate(node[:invalid_tag].to_s).inspect}"
          end
        end
      end

      tags = Transform.new.apply(tree.reject { |node| ignored?(node) })
      hash = {}

      tags.each do |tag|
        tag.each_key do |key|
          if hash.key?(key)
            raise InvalidRecord, "duplicate DMARC tag: #{key}"
          end
        end

        hash.merge!(tag)
      end

      validate!(hash)

      return hash
    end

    #
    # Determines whether a parse-tree node represents a tag that the lenient
    # parser dropped because it was unknown or had an invalid value.
    #
    # @param [Object] node
    #   The parse-tree node.
    #
    # @return [Boolean]
    #
    def self.ignored?(node)
      node.is_a?(Hash) && (node.key?(:unknown_tag) || node.key?(:invalid_tag))
    end

    #
    # Validates the parsed tags.
    #
    # @param [Hash{Symbol => Object}] tags
    #   The parsed tags.
    #
    # @raise [InvalidRecord]
    #   One of the tags has an invalid value.
    #
    def self.validate!(tags)
      if tags[:pct] && !(tags[:pct].is_a?(Integer) && tags[:pct].between?(0, 100))
        raise InvalidRecord, "pct must be an integer between 0 and 100"
      end

      if tags[:ri] && !(tags[:ri].is_a?(Integer) && tags[:ri].between?(0, 2**32 - 1))
        raise InvalidRecord, "ri must be an integer between 0 and 4294967295"
      end
    end

  end
end
