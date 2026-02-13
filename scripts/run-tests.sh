#!/bin/bash
# =============================================================================
# Run smoke tests on a running container
# Usage: docker compose exec ai-tools ./scripts/run-tests.sh
# =============================================================================

cd "$(dirname "$0")" || exit 1
exec ./test-tools.sh "$@"
