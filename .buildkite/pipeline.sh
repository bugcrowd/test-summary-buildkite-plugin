#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HASH=$(git rev-parse HEAD)
sed "s/@VERSION@/$HASH/g" "$SCRIPT_DIR/pipeline-sample.yml"
