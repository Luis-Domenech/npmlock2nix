#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

nix develop $DIR/../tests/tests-v2/examples-projects/single-dependency/shell.nix --command "node -e 'require(\"leftpad\")(123, 7);'"
