#!/bin/bash

function on_failure() {
    echo "Command failed with exit status: $?"
    if [[ "${BUILDKITE_PLUGIN_TEST_SUMMARY_FAIL_ON_ERROR:-false}" != "true" ]]; then
        echo "Suppressing failure so pipeline can continue (if you do not want this behaviour, set fail_on_error to true)"
        exit 0
    fi
}

function run_plugin() {
    if [[ "${BUILDKITE_PLUGIN_TEST_SUMMARY_RUN_WITHOUT_DOCKER:-false}" = "true" ]]; then
        PLUGIN_BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
        BUNDLE_GEMFILE="$PLUGIN_BASEDIR/Gemfile" "$PLUGIN_BASEDIR/bin/setup"
        BUNDLE_GEMFILE="$PLUGIN_BASEDIR/Gemfile" bundler exec "$PLUGIN_BASEDIR/bin/run"
    else
        DOCKER_REPO="bugcrowd/test-summary-buildkite-plugin"
        TAG=$(git describe --tags --exact-match 2> /dev/null || true)

        if [[ -n "$TAG" ]]; then
            echo "Found tag $TAG, pulling from docker hub"
            IMAGE="$DOCKER_REPO:$TAG"
            docker pull "$IMAGE"
        else
            echo "No tag found, building image locally"
            IMAGE="test-summary:$BUILDKITE_JOB_ID"
            docker build -t "$IMAGE" "$PLUGIN_BASEDIR"
        fi

        docker run --rm \
        --mount type=bind,src="$(command -v buildkite-agent)",dst=/usr/bin/buildkite-agent \
        --mount type=bind,src=/tmp,dst=/tmp \
        -e BUILDKITE_BUILD_ID -e BUILDKITE_JOB_ID -e BUILDKITE_PLUGINS \
        -e BUILDKITE_AGENT_ID -e BUILDKITE_AGENT_ACCESS_TOKEN -e BUILDKITE_AGENT_ENDPOINT   \
        -e HTTP_PROXY -e HTTPS_PROXY \
        "$IMAGE"
    fi
}