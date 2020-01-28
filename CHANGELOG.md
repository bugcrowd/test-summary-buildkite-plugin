# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v1.11.0](https://github.com/bugcrowd/test-summary-buildkite-plugin/compare/v1.10.0...v1.11.0) - 2020-01-28
- Forward `HTTP_PROXY` ENV var to respect proxies [#58](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/58)

## [v1.10.0](https://github.com/bugcrowd/test-summary-buildkite-plugin/compare/v1.9.1...v1.10.0) - 2019-10-12
- Support TAP version 12 plus skipped and TODO tests [#54](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/54)

## [v1.9.1](https://github.com/bugcrowd/test-summary-buildkite-plugin/compare/v1.9.0...v1.9.1) - 2019-05-30
- Fix Checkstyle formatter to be more tolerant of optional attributes [#52](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/52)

## [v1.9.0](https://github.com/bugcrowd/test-summary-buildkite-plugin/compare/v1.8.0...v1.9.0) - 2019-02-21
- Fix bin/run-dev to work with the new array syntax [#45](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/45) (thanks @philwo)
- Update buildkite css files in test layout [#46](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/46)
- Update `MAX_MARKDOWN_SIZE` to 100kb [#47](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/47) (thanks @ticky)
- Move docker images to the bugcrowd organisation [#48](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/48)

## [v1.8.0](https://github.com/bugcrowd/test-summary-buildkite-plugin/compare/v1.7.2...v1.8.0) - 2018-12-14
- Correctly link to jobs post buildkite update [#43](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/43)
- JUnit: Allow disabling the message or details if they aren't relevant [#44](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/44)

## [v1.7.2](https://github.com/bugcrowd/test-summary-buildkite-plugin/compare/v1.7.1...v1.7.2) - 2018-11-20
- Mount `/tmp` into the container to support `agent-socket` experimental feature [#40](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/40) (thanks @dreyks)
- Update README example to use plugin array syntax [#41](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/41)

## [v1.7.1](https://github.com/bugcrowd/test-summary-buildkite-plugin/compare/v1.7.0...v1.7.1) - 2018-10-11
- Fix error handling when truncating and an input fails to download [#38](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/38)

## [v1.7.0](https://github.com/bugcrowd/test-summary-buildkite-plugin/compare/v1.6.0...v1.7.0) - 2018-09-26
- JUnit: Expose classname if file attribute does not exist
  [#33](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/33)/[#35](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/35) (thanks @timnew)
- Add support for checkstyle
  [#34](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/34)/[#36](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/36) (thanks @timnew)

## [v1.6.0](https://github.com/bugcrowd/test-summary-buildkite-plugin/compare/v1.5.0...v1.6.0) - 2018-08-06
- Remove undocumented count-only formatter [#28](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/28)
- JUnit: support custom summary formats [#29](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/29)

## [v1.5.0](https://github.com/bugcrowd/test-summary-buildkite-plugin/compare/v1.4.0...v1.5.0) - 2018-07-25
- JUnit: Don't show an empty message when it's not provided [#21](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/21)
- Remove redcarpet workarounds [#22](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/22)
- Avoid blank lines in html details because CommonMark [#25](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/25)
    (thanks for the bug report by @joscha)

## [v1.4.0](https://github.com/bugcrowd/test-summary-buildkite-plugin/compare/v1.3.0...v1.4.0) - 2018-06-17
- Update plugin.yml and re-enable plugin-linter [#14](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/14) (@toolmantim)
- Workaround redcarpet formatting issues [#17](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/17)
- Truncate failures when markdown is too large [#18](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/18)

## [v1.3.0](https://github.com/bugcrowd/test-summary-buildkite-plugin/compare/v1.2.0...v1.3.0) - 2018-05-10
- Return zero exit status on error [#11](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/11)
- Junit: Handle testsuite objects nested inside testsuites [#12](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/12)
- Fallback to simpler formats if markdown is too large [#13](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/13)

## [v1.2.0](https://github.com/bugcrowd/test-summary-buildkite-plugin/compare/v1.1.0...v1.2.0) - 2018-05-04
- HTML escape output [#6](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/6)
- Junit: Support `error` elements and include the message [#7](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/7)

## [v1.1.0](https://github.com/bugcrowd/test-summary-buildkite-plugin/compare/v1.0.0...v1.1.0) - 2018-05-01

- Remove nokogiri dependency and use ruby alpine [#1](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/1)
- plugin.yml [#2](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/2)
- Links to the relevant jobs [#3](https://github.com/bugcrowd/test-summary-buildkite-plugin/pull/3)
