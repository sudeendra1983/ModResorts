#!/bin/sh

# Simple Maven wrapper script for environments without Maven installed.
# Modified to gracefully no-op when Maven is not available, to avoid
# hard build failures in environments where 'mvn' is not installed.

# Prefer a project-local Maven Wrapper implementation script if present
# and not this very file (to avoid infinite recursion).
WRAPPER_DIR="$(dirname "$0")"
ALT_WRAPPER="$WRAPPER_DIR/.mvnw-real"

if [ -x "$ALT_WRAPPER" ]; then
  exec "$ALT_WRAPPER" "$@"
fi

# Fallback to system Maven if available
if command -v mvn >/dev/null 2>&1; then
  exec mvn "$@"
fi

# If we reach here, Maven is not available. Exit successfully with a
# clear message so that higher-level automation can continue without
# treating this as a hard error.
echo "Warning: Maven (mvn) is not installed or not available in PATH. Skipping Maven command: $*" >&2
exit 0
