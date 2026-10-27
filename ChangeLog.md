### 0.4.0 / 2026-10-26

* Add `strict: true` parsing mode to reject unknown tags and invalid tag values.
* Return `nil` for non-numeric report integers (`count`, `pct`) instead of coercing them to `0`.
* Disable network access (`NONET`) explicitly when parsing XML reports.
* Reject DNS labels with leading or trailing hyphens.
* Set explicit DNS query timeouts.
* Reject XML reports larger than 25 MiB.

### 0.3.1 / 2026-10-26

* Update the gemspec maintainer metadata to list only the fork's author.

### 0.3.0 / 2026-10-26

* Raise `DMARCator::InvalidReport` for malformed XML reports instead of returning an empty report.
* Return `nil` for a non-numeric report `version` instead of raising `ArgumentError`.
* Return `nil` for a non-numeric report timestamp instead of coercing it to the Unix epoch.
* Add `DMARCator::Uri#eql?` and `#hash` for correct Hash/Set semantics.
* Harden `DMARCator.validate_domain` against CVE-2026-80213 (63-octet label limit and 248-octet total limit).
* Warn at load time when the `resolv` gem is affected by CVE-2026-80212/CVE-2026-80213.
* Require Ruby >= 3.3.13 to pick up the Regexp compilation fixes behind GitLab's CVE-2026-89078, CVE-2026-93577, CVE-2026-97229 and CVE-2026-110264.

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

