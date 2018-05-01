# Test Summary Buildkite Plugin

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) that adds a single annotation
for all your test failures using
[buildkite-agent annotate](https://buildkite.com/docs/agent/v3/cli-annotate).

Supported formats:

* JUnit
* [TAP](https://testanything.org)^
* Plain text files with one failure per line

\^ Current TAP support is fairly limited. If you have an example TAP file that is not being interpreted correctly,
feel free to open an issue or pull request.

## Example

Upload test results as artifacts using any supported format. If you include the `$BUILDKITE_JOB_ID` in the path,
a link to the build will be included in the annotation.
Some examples:

```yaml
steps:
  - label: rspec
    command: rspec
    parallelism: 10
    # With spec_helper.rb:
    # RSpec.configure do |config|
    #   config.add_formatter('RspecJunitFormatter', "artifacts/rspec-#{ENV['BUILDKITE_JOB_ID']}.xml")
    # end
    artifact_paths: "artifacts/*"

  - label: ava
    command: bash -c "yarn --silent test --tap > artifacts/ava.tap"
    artifact_paths: "artifacts/*"

  - label: rubocop
    # The emacs format is plain text with one failure per line
    command: rubocop -f emacs -o artifacts/rubocop.txt
    artifact_paths: "artifacts/*"
```

Wait for all the tests to finish:

```yaml
  - wait: ~
    continue_on_failure: true
```

Add a build step using the test-summary plugin:

```yaml
  - label: annotate
    plugins:
      bugcrowd/test-summary#v1.1.0:
        inputs:
          - label: rspec
            artifact_path: artifacts/rspec*
            type: junit
          - label: ava
            artifact_path: artifacts/ava.tap
            type: tap
          - label: rubocop
            artifact_path: artifacts/rubocop.txt
            type: oneline
        formatter:
          type: details
        context: test-summary
```

See buildkite annotation of all the failures. There are some example annotations included below.

## Configuration

### Inputs

The plugin takes a list of input sources. Each input source has:

* `label:` the name used in the heading to identify the test group.
* `artifact_path:` a glob used to download one or more artifacts.
* `type:` one of `junit`, `tap` or `oneline`.
* `encoding:` The file encoding to use. Defaults to `UTF-8`.
* `strip_colors:` Remove ANSI color escape sequences. Defaults to `false`.
* `crop:` (`oneline` type only) Number of lines to crop from the start and end of the file,
  to get around default headers and footers. Eg:

```yaml
crop:
  start: 3
  end: 2
```

* `job_id_regex`: Ruby regular expression to extract the `job_id` from the artifact path. It must contain
  a named capture with the name `job_id`. Defaults to
  `(?<job_id>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})`.

### Formatter

There are two formatter types, `summary` and `details`.

The `summary` formatter includes a single line for each failure.

![example summary annotation](doc/summary.png)

The `details` formatter
includes extra information about the failure in an accordion (if available).
This is the default option.

![example details annotation](doc/details.png)

Other formatter options are:

* `show_first:` The number of failures to show before hiding the rest inside an accordion.
  If set to zero, all failures will be hidden by default. If set to a negative number, all failures
  will be shown. Defaults to 20.

### Other options

* `context:` The Buildkite annotation context. Defaults to `test-summary`.
* `style:` Set the annotation style. Defaults to `error`.

## Developing

To run the tests:

    docker-compose run --rm test rspec

If you have ruby set up, you can just run:

    bundle install
    rspec

To generate sample markdown based on the files in `spec/sample_artifacts`:

    bin/run-dev

### Release process

1. Update [version.rb](lib/test_summary_buildkite_plugin/version.rb)
2. Update version in README example
3. Update [CHANGELOG.md](./CHANGELOG.md)
4. Push to github and ensure tests pass
5. `docker build -t tessereth/test-summary-buildkite-plugin:vx.x.x .`
6. `git tag --sign vx.x.x -m "Release vx.x.x"`
7. `docker push tessereth/test-summary-buildkite-plugin:vx.x.x`
8. `git push origin vx.x.x`
9. Copy changelog entry to github release notes
