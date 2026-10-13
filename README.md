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
# => ["0"]

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

## Requirements

* [Ruby] >= 3.0.0
* [parslet] >= 1.0.0, < 3.0.0
* [nokogiri] >= 1.10
* [bigdecimal] >= 1.0

## Testing

To run the RSpec tests:

```sh
rake spec
```

To test the parser against the bundled Alexa Top 500 fixture:

```sh
rake spec:gauntlet
```

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
