### Release process

1. Update [version.rb](lib/test_summary_buildkite_plugin/version.rb)
2. Update version in README example
3. Update [CHANGELOG.md](./CHANGELOG.md)
4. Ensure screenshots are up to date
5. Push to github and ensure tests pass
7. `export NEXT_VERSION=vx.x.x`
6. `docker build -t bugcrowd/test-summary-buildkite-plugin:$NEXT_VERSION .`
7. `git tag --sign $NEXT_VERSION -m "Release $NEXT_VERSION"`
8. `docker push bugcrowd/test-summary-buildkite-plugin:$NEXT_VERSION`
9. `git push origin $NEXT_VERSION`
10. Copy changelog entry to github release notes
