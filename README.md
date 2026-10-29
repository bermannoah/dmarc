# DMARCator

[![Gem Version](https://badge.fury.io/rb/dmarcator.svg)](https://badge.fury.io/rb/dmarcator)
[![YARD Docs](https://img.shields.io/badge/yard-docs-blue.svg)](https://rubydoc.info/gems/dmarcator)

DMARCator is a Ruby library for parsing and querying [DMARC] records.

> **DMARCator is a fork of the [`dmarc`][dmarc-gem] gem, originally created by
> Davis Gallinghouse at [Trail of Bits].** It keeps the original MIT license and
> credits its authors, but ships under a new name with additional hardening and
> a stricter parser. See [Acknowledgments](#acknowledgments) below.

[DMARC] policies are published as DNS TXT records at `_dmarc.<domain>`. This
library parses those records into a structured `DMARCator::Record`, queries them
directly through Ruby's `Resolv` DNS client, and parses the XML aggregate
reports those policies generate.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "dmarcator"
```

And then execute:

```sh
bundle install
```

Or install it yourself:

```sh
gem install dmarcator
```

The gem is loaded via:

```ruby
require "dmarcator"
```

## Example

Parse a DMARC record:

```ruby
require "dmarcator"

record = DMARCator::Record.parse(
  "v=DMARC1; p=reject; rua=mailto:d@rua.agari.com; ruf=mailto:d@ruf.agari.com; fo=1"
)

record.v
# => :DMARC1

record.p
# => :reject

record.adkim
# => :r

record.aspf
# => :r

record.fo
# => ["1"]

record.pct
# => 100

record.rf
# => :afrf

record.ri
# => 86400

record.rua
# => [#<DMARCator::Uri ... @uri=#<URI::MailTo mailto:d@rua.agari.com>, @size=nil, @unit=nil>]

record.ruf
# => [#<DMARCator::Uri ... @uri=#<URI::MailTo mailto:d@ruf.agari.com>, @size=nil, @unit=nil>]

record.sp
# => :reject
```

Query the DMARC record for a domain:

```ruby
record = DMARCator::Record.query("twitter.com")
# => #<DMARCator::Record ... @p=:reject, @rua=[...], ...>
```

Domains must be ASCII (A-labels): pass punycode such as
`xn--mnchen-3ya.de` rather than `münchen.de`. A lookup failure raises
`DMARCator::ResolutionError`; `nil` only means the domain genuinely has no
DMARC record.

## Strict parsing

By default, unknown tags and tags with invalid values are ignored. Pass
`strict: true` to reject them instead:

```ruby
DMARCator::Record.parse("v=DMARC1; p=none; pct=abc", strict: true)
# => DMARCator::InvalidRecord: invalid DMARC tag value: "pct=abc"
```

## Parsing XML reports

Parse a DMARC aggregate/forensic report:

```ruby
report = DMARCator::Report.new(xml_string)

report.version
# => 0.1e0

report.metadata.org_name
# => "google.com"

report.policy.domain
# => "opserv.io"

report.records.first.source_ip
# => "209.85.220.69"
```

## DNS transport

By default, DMARC lookups use plain DNS through `Resolv`. Encrypted transports
can be selected with environment variables; no DNS provider is baked in:

```sh
# DNS over HTTPS (RFC 8484)
export DMARCATOR_DNS=doh
export DMARCATOR_DOH_URL=https://cloudflare-dns.com/dns-query
export DMARCATOR_DOH_IP=1.1.1.1          # optional: pin the endpoint

# DNS over TLS (RFC 7858)
export DMARCATOR_DNS=dot
export DMARCATOR_DOT_SERVER=1.1.1.1:853
export DMARCATOR_DOT_SNI=cloudflare-dns.com   # optional: name to verify

# optional, both transports (seconds, default 5)
export DMARCATOR_DNS_TIMEOUT=5
```

Certificates are always verified. `DMARCATOR_DOH_IP` pins the address so the
DoH endpoint does not have to be resolved first; TLS still verifies the URL's
hostname.

Encrypted transports fail closed: a transport failure raises
`DMARCator::ResolutionError` instead of being reported as a domain without a
DMARC record. This applies to every transport, including plaintext —
`Resolv` returns an empty result for NXDOMAIN and raises for timeouts and
other failures, so a failed lookup is never mistaken for an absent record.
Plaintext remains the default because forcing a public resolver breaks private
and split-horizon zones, and some networks block port 853 or public resolvers.

A resolver can also be built explicitly:

```ruby
resolver = DMARCator::Resolver::DoH.new(url: "https://dns.example/dns-query")
record   = DMARCator::Record.query("example.com", resolver)
```

## Security

DMARC records and XML reports are treated as untrusted input:

* XML reports are parsed with network access disabled (`NONET`), so external
  entities are never resolved or fetched.
* Reports larger than `DMARCator::Report.max_report_bytes` (25 MiB by
  default) are rejected before parsing. Parsing builds a DOM roughly 13× the
  input size, so lower the limit to bound memory:

  ```ruby
  DMARCator::Report.max_report_bytes = 5 * 1024 * 1024
  ```
* A warning is emitted at load time if the bundled `resolv` gem is affected by
  CVE-2026-80212/CVE-2026-80213.
* Domain names are validated before resolution (labels ≤ 63 octets, total ≤
  248 octets, no leading/trailing hyphens).
* Optional [DNS over HTTPS and DNS over TLS](#dns-transport) transports verify
  TLS certificates and fail closed: a transport failure raises
  `DMARCator::ResolutionError` rather than being reported as a domain without a
  DMARC record, so a blocked or downgraded lookup can never silently enforce no
  policy. Plaintext lookups fail closed the same way. DoH responses must be
  `application/dns-message` and are capped at 65,535 bytes.

## Requirements

* [Ruby] >= 3.3.13
* [parslet] >= 1.0.0, < 3.0.0
* [nokogiri] >= 1.10
* [bigdecimal] >= 1.0

## Testing

To run the RSpec tests:

```sh
rake spec
```

## Releasing

Every published version must have an annotated tag pointing at the commit that
was built, so a gem can always be traced back to its source:

```sh
# 1. Bump VERSION in lib/dmarcator/version.rb and add a ChangeLog entry.
# 2. Commit the release.
git commit -am "Bump version to X.Y.Z"

# 3. Tag that commit before building anything.
git tag -a vX.Y.Z -m "dmarcator X.Y.Z"

# 4. Push the commit and its tags.
git push origin main --follow-tags

# 5. Build and publish from the tagged checkout.
gem build dmarc.gemspec
gem push dmarcator-X.Y.Z.gem
```

Tag before publishing, never after: a tag without a published gem, or a gem
without a tag, makes the two hard to reconcile later.

## License

This project is released under the MIT License. See the [LICENSE.txt] file for
details.

## Acknowledgments

DMARCator is a fork of [`dmarc`][dmarc-gem], a DMARC record parser created by
Davis Gallinghouse at [Trail of Bits] and released under the MIT License.

This fork renames the `DMARC` module to `DMARCator` (loaded via
`require "dmarcator"`) while keeping the original API shape, and adds:

* strict `mailto:`-only handling for `rua`/`ruf` report URIs,
* validation for required and ranged tags (`p`, `pct`, `ri`) and duplicate tags,
* a DNS query path that selects the `v=DMARC1` TXT record per RFC 7489,
* hardened packaging and test fixtures.

The DMARC XML report parser is ported from [`dmarc_parser`][dmarc-parser-gem],
created by D Salko and released under the MIT License.

[DMARC]: https://www.rfc-editor.org/rfc/rfc7489
[dmarc-gem]: https://rubygems.org/gems/dmarc
[dmarc-parser-gem]: https://rubygems.org/gems/dmarc_parser
[Trail of Bits]: https://www.trailofbits.com
[Ruby]: https://www.ruby-lang.org
[parslet]: https://kschiess.github.io/parslet/
[nokogiri]: https://nokogiri.org
[bigdecimal]: https://github.com/ruby/bigdecimal
[LICENSE.txt]: LICENSE.txt
