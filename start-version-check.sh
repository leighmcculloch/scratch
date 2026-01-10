#!/usr/bin/env bash

# Version persistence and checking for Stellar Quickstart
# This file contains the function to be integrated into the main start script
#
# Issue: https://github.com/stellar/quickstart/issues/762
#
# When using persistent mode (volume mounted at /opt/stellar), users may
# upgrade the quickstart container but still have old configuration and
# scripts from a previous version. This can cause failures when the new
# container expects different binaries or configuration formats.
#
# This function:
# 1. Persists the quickstart version in /opt/stellar/.quickstart-version on first run
# 2. On subsequent runs, compares the persistent version with the current version
# 3. If versions differ, displays a warning with a link to documentation

QUICKSTART_VERSION_FILE="/opt/stellar/.quickstart-version"
README_PERSISTENT_URL="https://github.com/stellar/quickstart#persistent-mode"

function check_quickstart_version() {
    # Only relevant in persistent mode (when /opt/stellar is mounted)
    if [ -f "/opt/stellar/.docker-ephemeral" ]; then
        # Ephemeral mode - no version tracking needed
        return 0
    fi

    local current_version="${REVISION:-unknown}"

    if [ -f "$QUICKSTART_VERSION_FILE" ]; then
        local persistent_version
        persistent_version=$(cat "$QUICKSTART_VERSION_FILE" 2>/dev/null)

        if [ "$persistent_version" != "$current_version" ]; then
            echo ""
            echo "========================================================================"
            echo "WARNING: Quickstart version mismatch detected!"
            echo "========================================================================"
            echo ""
            echo "  Persistent version: $persistent_version"
            echo "  Current version: $current_version"
            echo ""
            echo "You are running a different version of quickstart than was previously"
            echo "used with this persistent volume. This may cause issues because:"
            echo ""
            echo "  - Configuration files in /opt/stellar may be outdated"
            echo "  - Scripts may reference binaries that no longer exist"
            echo "  - File formats or directory structures may have changed"
            echo ""
            echo "To resolve this, you can:"
            echo ""
            echo "  1. Start fresh: Remove the contents of your mounted volume and restart"
            echo "  2. Pin the version: Use the same quickstart image version as before"
            echo "  3. Update manually: Review and update configuration files as needed"
            echo ""
            echo "For more information about persistent mode limitations, see:"
            echo "  $README_PERSISTENT_URL"
            echo ""
            echo "========================================================================"
            echo ""

            # Update the persistent version after warning
            echo "$current_version" > "$QUICKSTART_VERSION_FILE"
        fi
    else
        # First run with this persistent volume - persist the version
        echo "$current_version" > "$QUICKSTART_VERSION_FILE"
    fi
}
