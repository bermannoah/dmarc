require 'spec_helper'
require 'dmarcator'

RSpec.describe 'DMARCator error hierarchy' do
  it 'has a common base class' do
    expect(DMARCator::Error.ancestors).to include(StandardError)

    [
      DMARCator::InvalidRecord,
      DMARCator::InvalidReport,
      DMARCator::ResolutionError
    ].each do |klass|
      expect(klass.ancestors).to include(DMARCator::Error)
    end
  end

  it 'does not expose the parser implementation' do
    expect(DMARCator::InvalidRecord.ancestors).not_to include(Parslet::ParseFailed)
  end

  it 'lets callers rescue one base class' do
    expect { DMARCator::Record.parse('v=XXXXXXXX') }.to raise_error(DMARCator::Error)
    expect { DMARCator::Report.new('not xml') }.to raise_error(DMARCator::Error)
  end

  it 'keeps the underlying cause for parse failures' do
    expect {
      DMARCator::Record.parse('!!!')
    }.to raise_error(DMARCator::InvalidRecord) { |error|
      expect(error.cause).to be_a(Parslet::ParseFailed)
    }
  end
end
