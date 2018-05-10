# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
