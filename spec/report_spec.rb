# frozen_string_literal: true

require 'spec_helper'
require 'dmarcator/report'
require 'bigdecimal'

RSpec.describe DMARCator::Report do
  let(:example_path) { File.join(__dir__, 'support', 'complete.xml') }
  let(:google_path)  { File.join(__dir__, 'support', 'google.xml') }

  let(:xml_report)    { File.read(example_path) }
  let(:google_report) { File.read(google_path) }

  it 'has a version number' do
    expect(DMARCator::VERSION).not_to be_nil
  end

  it 'reads report version if available' do
    report = described_class.new(xml_report)
    expect(report.version).to eq(BigDecimal('0.1'))

    google = described_class.new(google_report)
    expect(google.version).to be_nil
  end

  it 'reads report metadata' do
    report = described_class.new(xml_report)

    expect(report.metadata.org_name).to eq('google.com')
    expect(report.metadata.email).to eq('noreply-dmarc-support@google.com')
    expect(report.metadata.extra_contact_info).to eq('https://support.google.com/a/answer/2466580')
    expect(report.metadata.report_id).to eq('3114726731964606297')
    expect(report.metadata.begin_at).to eq(Time.at(1_593_648_000))
    expect(report.metadata.end_at).to eq(Time.at(1_593_734_399))
    expect(report.metadata.errors).to eq(['some error', 'another error'])
  end

  it 'reads policy published' do
    report = described_class.new(xml_report)

    expect(report.policy.domain).to eq('opserv.io')
    expect(report.policy.adkim).to eq('r')
    expect(report.policy.aspf).to eq('r')
    expect(report.policy.p).to eq('none')
    expect(report.policy.sp).to eq('none')
    expect(report.policy.pct).to eq(100)
    expect(report.policy.fo).to eq('1')
  end

  it 'reads report records' do
    report = described_class.new(xml_report)
    record = report.records.first

    expect(record.source_ip).to eq('209.85.220.69')
    expect(record.count).to eq(96)
    expect(record.disposition).to eq('none')
    expect(record.dkim).to eq('fail')
    expect(record.spf).to eq('fail')

    expect(record.reasons.count).to eq(2)
    expect(record.reasons.first.type).to eq('local_policy')
    expect(record.reasons.first.comment).to eq('arc=pass')
    expect(record.reasons.last.type).to eq('other')
    expect(record.reasons.last.comment).to eq('dkim=pass')

    expect(record.envelope_to).to eq('envelope-to.io')
    expect(record.envelope_from).to eq('envelope-from.io')
    expect(record.header_from).to eq('opserv.io')

    expect(record.auth_results.count).to eq(2)
    expect(record.auth_results.first.type).to eq('dkim')
    expect(record.auth_results.first.domain).to eq('condenast-com-tw.20150623.gappssmtp.com')
    expect(record.auth_results.first.result).to eq('pass')
    expect(record.auth_results.first.selector).to eq('20150623')
    expect(record.auth_results.last.type).to eq('spf')
    expect(record.auth_results.last.domain).to eq('condenast.com.tw')
    expect(record.auth_results.last.result).to eq('neutral')
    expect(record.auth_results.last.scope).to eq('mfrom')
  end
end
