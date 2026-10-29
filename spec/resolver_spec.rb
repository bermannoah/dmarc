# frozen_string_literal: true

require 'spec_helper'
require 'dmarcator/resolver'

RSpec.describe DMARCator::Resolver do
  describe '.mode' do
    it 'defaults to plaintext' do
      expect(described_class.mode({})).to eq('plaintext')
    end

    it 'reads DMARCATOR_DNS' do
      expect(described_class.mode('DMARCATOR_DNS' => 'doh')).to eq('doh')
    end

    it 'strips and downcases' do
      expect(described_class.mode('DMARCATOR_DNS' => "  DoT \n")).to eq('dot')
    end

    it 'treats an empty value as the default' do
      expect(described_class.mode('DMARCATOR_DNS' => '')).to eq('plaintext')
    end
  end

  describe '.build' do
    it 'builds a plaintext resolver by default' do
      expect(described_class.build(env: {})).to be_a(Resolv::DNS)
    end

    it 'builds a DoH resolver' do
      resolver = described_class.build(
        env: { 'DMARCATOR_DNS' => 'doh', 'DMARCATOR_DOH_URL' => 'https://dns.example/dns-query' }
      )

      expect(resolver).to be_a(DMARCator::Resolver::DoH)
    end

    it 'builds a DoT resolver' do
      resolver = described_class.build(
        env: { 'DMARCATOR_DNS' => 'dot', 'DMARCATOR_DOT_SERVER' => 'dns.example' }
      )

      expect(resolver).to be_a(DMARCator::Resolver::DoT)
    end

    it 'accepts an explicit mode' do
      expect(described_class.build(mode: 'plaintext', env: {})).to be_a(Resolv::DNS)
    end

    it 'rejects an unknown mode' do
      expect {
        described_class.build(env: { 'DMARCATOR_DNS' => 'carrier-pigeon' })
      }.to raise_error(ArgumentError, /unknown DMARCATOR_DNS/)
    end

    it 'requires a DoH endpoint' do
      expect {
        described_class.build(env: { 'DMARCATOR_DNS' => 'doh' })
      }.to raise_error(ArgumentError, /DMARCATOR_DOH_URL/)
    end

    it 'requires a DoT server' do
      expect {
        described_class.build(env: { 'DMARCATOR_DNS' => 'dot' })
      }.to raise_error(ArgumentError, /DMARCATOR_DOT_SERVER/)
    end
  end
end

RSpec.describe 'encrypted DNS transports' do
  let(:txt_class) { Resolv::DNS::Resource::IN::TXT }
  let(:name) { '_dmarc.example.com' }

  #
  # Encodes a response to +query+, echoing its id and question so the
  # transport's validation passes.
  #
  def response_for(query, answers: [], rcode: 0, tc: 0, question: nil, id: nil)
    question_name, question_type = query.question.first

    message = Resolv::DNS::Message.new(id || query.id)
    message.qr = 1
    message.rd = 1
    message.ra = 1
    message.tc = tc
    message.rcode = rcode
    message.add_question(question || question_name, question_type)

    answers.each { |answer_name, ttl, record| message.add_answer(answer_name, ttl, record) }

    message.encode
  end

  def txt(value)
    Resolv::DNS::Resource::IN::TXT.new(value)
  end

  shared_examples 'an encrypted transport' do
    it 'returns TXT records' do
      allow(resolver).to receive(:exchange) do |query|
        response_for(query, answers: [[name, 300, txt('v=DMARC1; p=reject')]])
      end

      records = resolver.getresources(name, txt_class)

      expect(records.map(&:strings)).to eq([['v=DMARC1; p=reject']])
    end

    it 'returns an empty array for NXDOMAIN' do
      allow(resolver).to receive(:exchange) do |query|
        response_for(query, rcode: Resolv::DNS::RCode::NXDomain)
      end

      expect(resolver.getresources(name, txt_class)).to eq([])
    end

    it 'raises for server failures' do
      allow(resolver).to receive(:exchange) do |query|
        response_for(query, rcode: Resolv::DNS::RCode::ServFail)
      end

      expect {
        resolver.getresources(name, txt_class)
      }.to raise_error(DMARCator::ResolutionError, /rcode 2/)
    end

    it 'raises on an empty response' do
      allow(resolver).to receive(:exchange).and_return('')

      expect {
        resolver.getresources(name, txt_class)
      }.to raise_error(DMARCator::ResolutionError, /empty DNS response/)
    end

    it 'raises on a malformed response' do
      # Valid header claiming one question, but no question section.
      allow(resolver).to receive(:exchange).and_return([1, 0x0100, 1, 0, 0, 0].pack('nnnnnn'))

      expect {
        resolver.getresources(name, txt_class)
      }.to raise_error(DMARCator::ResolutionError, /malformed DNS response/)
    end

    it 'raises when the transaction id does not match' do
      allow(resolver).to receive(:exchange) do |query|
        response_for(query, id: query.id ^ 0xFFFF)
      end

      expect {
        resolver.getresources(name, txt_class)
      }.to raise_error(DMARCator::ResolutionError, /transaction mismatch/)
    end

    it 'raises when the question does not match' do
      allow(resolver).to receive(:exchange) do |query|
        response_for(query, question: Resolv::DNS::Name.create('_dmarc.attacker.test'))
      end

      expect {
        resolver.getresources(name, txt_class)
      }.to raise_error(DMARCator::ResolutionError, /question mismatch/)
    end

    it 'raises on a truncated response' do
      allow(resolver).to receive(:exchange) do |query|
        response_for(query, tc: 1)
      end

      expect {
        resolver.getresources(name, txt_class)
      }.to raise_error(DMARCator::ResolutionError, /truncated/)
    end

    it 'follows a CNAME to the target name' do
      allow(resolver).to receive(:exchange) do |query|
        if query.question.first[0].to_s.include?('cdn.example')
          response_for(query, answers: [[query.question.first[0], 60, txt('v=DMARC1; p=none')]])
        else
          cname = Resolv::DNS::Resource::IN::CNAME.new(Resolv::DNS::Name.create('_dmarc.cdn.example'))
          response_for(query, answers: [[query.question.first[0], 60, cname]])
        end
      end

      expect(resolver.getresources(name, txt_class).map(&:strings)).to eq([['v=DMARC1; p=none']])
    end

    it 'stops following CNAMEs after a bounded number of hops' do
      calls = 0

      allow(resolver).to receive(:exchange) do |query|
        calls += 1
        cname = Resolv::DNS::Resource::IN::CNAME.new(Resolv::DNS::Name.create('loop.example'))
        response_for(query, answers: [[query.question.first[0], 60, cname]])
      end

      expect(resolver.getresources(name, txt_class)).to eq([])
      expect(calls).to be <= DMARCator::Resolver::Encrypted::MAX_CNAME_DEPTH + 1
    end
  end

  describe DMARCator::Resolver::DoH do
    let(:resolver) { described_class.new(url: 'https://dns.example/dns-query') }

    it_behaves_like 'an encrypted transport'

    describe '.from_env' do
      it 'requires an https URL' do
        expect {
          described_class.from_env('DMARCATOR_DOH_URL' => 'http://dns.example/dns-query')
        }.to raise_error(ArgumentError, /https URL/)
      end

      it 'accepts an IP-pinned endpoint' do
        resolver = described_class.from_env(
          'DMARCATOR_DOH_URL' => 'https://dns.example/dns-query',
          'DMARCATOR_DOH_IP' => '192.0.2.1',
          'DMARCATOR_DNS_TIMEOUT' => '2'
        )

        expect(resolver.ipaddr).to eq('192.0.2.1')
        expect(resolver.timeout).to eq(2)
      end

      it 'rejects a non-numeric timeout' do
        expect {
          described_class.from_env(
            'DMARCATOR_DOH_URL' => 'https://dns.example/dns-query',
            'DMARCATOR_DNS_TIMEOUT' => 'soon'
          )
        }.to raise_error(ArgumentError)
      end
    end

    describe '#exchange' do
      def stub_http(response)
        http = instance_double(Net::HTTP)

        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:verify_mode=)
        allow(http).to receive(:open_timeout=)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:write_timeout=)
        allow(http).to receive(:start).and_yield(http)
        allow(http).to receive(:request).and_return(response)

        http
      end

      def stub_response(code: '200', body: '', content_type: 'application/dns-message')
        response = instance_double(Net::HTTPResponse, code: code, body: body)

        allow(response).to receive(:[]).with('content-type').and_return(content_type)

        response
      end

      it 'sends a POST with the DNS message and returns the body' do
        wire = Resolv::DNS::Message.new(1).encode
        http = stub_http(stub_response(body: wire))

        expect(http).to receive(:use_ssl=).with(true)
        expect(http).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER)
        expect(http).to receive(:request) do |request|
          expect(request['content-type']).to eq('application/dns-message')
          expect(request.body).to eq(wire)
          stub_response(body: wire)
        end

        expect(resolver.send(:exchange, Resolv::DNS::Message.new(1))).to eq(wire)
      end

      it 'raises when the endpoint returns a non-success status' do
        stub_http(stub_response(code: '500'))

        expect {
          resolver.send(:exchange, Resolv::DNS::Message.new(1))
        }.to raise_error(DMARCator::ResolutionError, /HTTP 500/)
      end

      it 'raises when the content type is not a DNS message' do
        stub_http(stub_response(content_type: 'text/html'))

        expect {
          resolver.send(:exchange, Resolv::DNS::Message.new(1))
        }.to raise_error(DMARCator::ResolutionError, /unexpected content-type/)
      end

      it 'raises when the response body is oversized' do
        oversized = 'x' * (described_class::MAX_RESPONSE_BYTES + 1)
        stub_http(stub_response(body: oversized))

        expect {
          resolver.send(:exchange, Resolv::DNS::Message.new(1))
        }.to raise_error(DMARCator::ResolutionError, /exceeds maximum size/)
      end

      it 'wraps transport errors' do
        allow(Net::HTTP).to receive(:new).and_raise(Errno::ECONNREFUSED)

        expect {
          resolver.send(:exchange, Resolv::DNS::Message.new(1))
        }.to raise_error(DMARCator::ResolutionError, /DoH request failed/)
      end
    end
  end

  describe DMARCator::Resolver::DoT do
    let(:resolver) { described_class.new(host: 'dns.example') }

    it_behaves_like 'an encrypted transport'

    describe '.split_server' do
      it 'defaults the port' do
        expect(described_class.split_server('dns.example')).to eq(['dns.example', 853])
      end

      it 'parses host:port' do
        expect(described_class.split_server('dns.example:8853')).to eq(['dns.example', 8853])
      end

      it 'parses bracketed IPv6' do
        expect(described_class.split_server('[2001:db8::1]')).to eq(['2001:db8::1', 853])
        expect(described_class.split_server('[2001:db8::1]:8853')).to eq(['2001:db8::1', 8853])
      end

      it 'rejects malformed servers' do
        expect { described_class.split_server('') }.to raise_error(ArgumentError)
      end
    end

    describe '.from_env' do
      it 'uses the server as the verification name by default' do
        resolver = described_class.from_env('DMARCATOR_DOT_SERVER' => 'dns.example:8853')

        expect(resolver.host).to eq('dns.example')
        expect(resolver.port).to eq(8853)
        expect(resolver.sni).to eq('dns.example')
      end

      it 'allows an explicit verification name' do
        resolver = described_class.from_env(
          'DMARCATOR_DOT_SERVER' => '192.0.2.1',
          'DMARCATOR_DOT_SNI' => 'dns.example'
        )

        expect(resolver.sni).to eq('dns.example')
      end
    end
  end
end
