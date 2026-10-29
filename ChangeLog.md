### 0.7.0 / 2026-10-29

* Plaintext DNS lookups now fail closed: a lookup failure raises `DMARCator::ResolutionError` instead of being reported as a domain without a DMARC record. Previously a timeout or resolver failure looked like no policy, which failed open. This is a behavior change and applies to every transport.
* DoH responses must use the `application/dns-message` content type (RFC 8484) and are capped at 65,535 bytes.
* `DMARCator::Uri` no longer forwards calls to private methods of the wrapped `URI::MailTo`.
* Add a CI workflow that runs the specs on the minimum supported Ruby and the current release, loads the gem with warnings enabled, fails on YARD warnings, and builds the gem.

### 0.6.1 / 2026-10-29

* Remove a redundant `attr_reader :sp` that `Record#sp` already overrode, fixing a `method redefined; discarding old sp` warning emitted under `-w` (as CI enables).
* Add tests covering `Record#sp` falling back to `p` when `sp` is omitted.
* Document every report accessor, constant, and public class that YARD previously omitted; documentation coverage is now 100% with no warnings.
* Note the encrypted-transport guarantees in the README security section.
* No functional changes.

### 0.6.0 / 2026-10-28

* Add DNS over HTTPS (RFC 8484) and DNS over TLS (RFC 7858) transports, selected with `DMARCATOR_DNS` (`doh` or `dot`). No provider is bundled and plaintext remains the default.
* Encrypted transports verify TLS certificates, validate the response id, question and TC bit, and follow CNAMEs up to a bounded depth.
* Add `DMARCator::ResolutionError`; encrypted transport failures raise instead of being reported as a missing record.
* Add `DMARCator.default_resolver` and `DMARCator::Resolver.build` for explicit transport configuration.

### 0.5.1 / 2026-10-28

* Point the gem metadata (`homepage`, `source_code_uri`, `bug_tracker_uri`) at the renamed GitHub repository (`dmarc` → `dmarcator`).

### 0.5.0 / 2026-10-28

* Performance: extract each report record in a single pass over its children instead of one XPath query per field (roughly 3x faster `Report#records`).
* Performance: extract report metadata and policy in a single pass.
* Performance: build `Record#reasons` and `Record#auth_results` lazily, so callers that only read scalar fields skip roughly half of record construction.
* Performance: reuse one memoized parser and transform instance, making `Record.parse` roughly 30% faster.
* Add `DMARCator::Report.max_report_bytes` to configure the maximum accepted report size; parsing builds a DOM roughly 13x the input size, so lower it to bound memory.
* Report elements that appear more than once now consistently use the first value, matching prior behavior for records.
* Assign `policy_published` fields explicitly instead of by element name.

### 0.4.2 / 2026-10-28

* Do not raise when the loaded `resolv` version is not a valid gem version; an unparseable version is treated as unknown instead of failing at load time.
* Reject DMARC records larger than 4 KiB (`Parser::MAX_RECORD_BYTES`) before parsing to bound work on hostile input.
* Raise the documented `InvalidRecord`/`InvalidReport` for non-String input instead of `ArgumentError`, `TypeError`, or a silently empty report.

### 0.4.1 / 2026-10-28

* Accept a case-insensitive `mailto:` scheme in `rua`/`ruf` report URIs.
* Fix parsing of `rua`/`ruf` lists that mix valid and invalid URIs.
* Restrict `mailto:` address characters to a safe whitelist.
* Reject underscores in validated domain names.
* Remove the dead Alexa Top 500 scraping task and its fixture.
* Drop the `simplecov` development dependency.
* Housekeeping: remove dead rescue code, fix documentation typos, add frozen string literals, make `Uri` delegation private, and drop the deprecated `gem.test_files`.

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

