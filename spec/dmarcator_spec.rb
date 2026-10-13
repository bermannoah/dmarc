require 'spec_helper'
require 'dmarcator'

describe DMARCator do
  subject { described_class }

  describe ".query" do
    let(:txt_class) { Resolv::DNS::Resource::IN::TXT }
    let(:resolver)  { double("resolver") }

    def txt(strings)
      instance_double(txt_class, strings: strings)
    end

    it "returns the DMARC TXT record" do
      expect(resolver).to receive(:getresources)
        .with("_dmarc.google.com", txt_class)
        .and_return([txt(["v=DMARC1; p=reject; rua=mailto:mailauth-reports@google.com"])])

      expect(subject.query("google.com", resolver)).to eq(
        "v=DMARC1; p=reject; rua=mailto:mailauth-reports@google.com"
      )
    end

    it "ignores non-DMARC TXT records" do
      expect(resolver).to receive(:getresources)
        .with("_dmarc.google.com", txt_class)
        .and_return([
          txt(["not a dmarc record"]),
          txt(["v=DMARC1; p=reject"])
        ])

      expect(subject.query("google.com", resolver)).to eq("v=DMARC1; p=reject")
    end

    it "returns nil when multiple DMARC records exist" do
      expect(resolver).to receive(:getresources)
        .with("_dmarc.google.com", txt_class)
        .and_return([txt(["v=DMARC1; p=none"]), txt(["v=DMARC1; p=reject"])])

      expect(subject.query("google.com", resolver)).to be_nil
    end

    it "returns nil when no DMARC record exists" do
      expect(resolver).to receive(:getresources)
        .with("_dmarc.google.com", txt_class)
        .and_return([])

      expect(subject.query("google.com", resolver)).to be_nil
    end

    it "returns nil when the resolver raises ResolvError" do
      expect(resolver).to receive(:getresources).and_raise(Resolv::ResolvError)

      expect(subject.query("google.com", resolver)).to be_nil
    end

    it "rejects invalid domains" do
      expect { subject.query("foo bar") }.to raise_error(ArgumentError)
    end
  end
end
