# frozen_string_literal: true

require 'json'

#
# Shared helpers for the record-parser corpus.
#
# The corpus pins the parser's *current* behaviour so that a change to it is a
# deliberate, reviewable decision. It is a regression net, not an oracle for
# correctness: the assertions in parser_spec.rb describe what the parser should
# do, and the recorded outcomes here describe what it did when the corpus was
# last accepted.
#
# Regenerate after an intentional change:
#
#   ruby -Ilib script/generate_record_corpus.rb
#
module RecordCorpus
  module_function

  #
  # Reduces a parsed value to a JSON-comparable shape.
  #
  def canon(value)
    case value
    when Hash then value.map { |key, val| [key.to_s, canon(val)] }.sort_by(&:first)
    when Array then value.map { |val| canon(val) }
    when DMARCator::Uri
      { 'uri' => value.uri.to_s, 'size' => value.size, 'unit' => value.unit&.to_s }
    when Symbol then value.to_s
    else value
    end
  end

  #
  # Parses a record and returns its canonical outcome.
  #
  # Errors are recorded by class only: messages are allowed to change, and are
  # covered separately where the wording matters.
  #
  def outcome(record, strict:)
    { 'ok' => canon(DMARCator::Record.parse(record, strict: strict).to_h) }
  rescue DMARCator::Error => error
    { 'error' => error.class.name }
  end

  #
  # Builds the corpus cases for the given records.
  #
  def cases(records)
    records.map do |record|
      {
        'record' => record,
        'lenient' => outcome(record, strict: false),
        'strict' => outcome(record, strict: true)
      }
    end
  end

  #
  # The corpus records, one per line.
  #
  def records(path)
    File.readlines(path, chomp: true).reject(&:empty?)
  end
end
