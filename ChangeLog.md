### 0.2.0 / 2026-10-13

* Added DMARC XML report parsing, ported from the `dmarc_parser` gem by D Salko.
* Added `nokogiri` and `bigdecimal` runtime dependencies.

### 0.1.0 / 2026-10-13

* Forked from the Trail of Bits `dmarc` gem and published as `dmarcator`.
* Renamed the `DMARC` module to `DMARCator` (`require "dmarcator"`).
* Hardened parsing and DNS querying; see the README for details.

### 0.6.0 / 2024-01-24

Entries below this point refer to the original `dmarc` gem.


* {DMARC::Record.parse} now allows trailing whitespace, per DMARC spec.

### 0.5.0 / 2016-06-16

* Added {DMARC::Uri} to represent `mailto:dmarc@example.com!10m` URIs.

### 0.4.0 / 2016-06-10

* Added {DMARC::Record#to_h}.
* Added {DMARC::Record#adkim?}.
* Added {DMARC::Record#aspf?}.
* Added {DMARC::Record#fo?}.
* Added {DMARC::Record#p?}.
* Added {DMARC::Record#pct?}.
* Added {DMARC::Record#rf?}.
* Added {DMARC::Record#ri?}.
* Added {DMARC::Record#rua?}.
* Added {DMARC::Record#ruf?}.
* Added {DMARC::Record#sp?}.

### 0.3.0 / 2015-07-01

* Added {DMARC::Record.query}.
* Added {DMARC::Record#to_s}.
* Added {DMARC::InvalidRecord}.
* Deprecate {DMARC::Record.from_txt}.
* {DMARC::Record#v} now returns `:DMARC1`.
* {DMARC::Record#p} and {DMARC::Record#sp} now return Symbols
* {DMARC::Record#rua} and {DMARC::Record#ruf} will always return Arrays.
* Fixed a bug in {DMARC::Parser} with respect to order of tags.
* {DMARC::Parser::Transform} now coerces URIs into URI objects.

### 0.2.0 / 2014-10-20

* Added `DMARC::Error`.
* Added {DMARC::InvalidRecord}.
* Add support for parsing `fo` tokens.
* Ignore unknown tags instead of raising a parser exception.
* Ignore tags with invalid values instead of raising a parser exception.

### 0.1.0 / 2014-04-25

* Initial release.

