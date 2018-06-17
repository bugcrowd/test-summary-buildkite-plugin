### Release process

1. Update [version.rb](lib/test_summary_buildkite_plugin/version.rb)
2. Update version in README example
3. Update [CHANGELOG.md](./CHANGELOG.md)
4. Ensure screenshots are up to date
5. Push to github and ensure tests pass
6. `docker build -t tessereth/test-summary-buildkite-plugin:vx.x.x .`
7. `git tag --sign vx.x.x -m "Release vx.x.x"`
8. `docker push tessereth/test-summary-buildkite-plugin:vx.x.x`
9. `git push origin vx.x.x`
10. Copy changelog entry to github release notes
