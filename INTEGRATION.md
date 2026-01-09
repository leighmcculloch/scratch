# Quickstart Version Persistence - Integration Guide

This document describes how to integrate the version persistence feature into the Stellar Quickstart container.

## Problem

When using persistent mode (volume mounted at `/opt/stellar`), users may upgrade the quickstart container but the mounted volume retains old configuration and scripts from a previous version. This can cause failures, such as when `soroban-rpc` was renamed to `stellar-rpc` and persisted scripts still referenced the old binary name.

See: https://github.com/stellar/quickstart/issues/762

## Solution

Store the quickstart version in `/opt/stellar/.quickstart-version` and compare it on startup. If versions differ, display a warning with actionable guidance.

## Integration Steps

### 1. Add the version check function to the `start` script

Add the contents of `start-version-check.sh` to the `start` script, placing the function definition near the other utility functions.

### 2. Call the function during startup

In the `start()` function, call `check_quickstart_version` after `copy_defaults`:

```bash
function start() {
  # ... existing code ...

  copy_defaults
  check_quickstart_version  # Add this line

  # ... rest of function ...
}
```

### 3. Alternative: Call early in main()

For earlier detection, call it in `main()` before the full startup:

```bash
function main() {
  process_args $*
  check_quickstart_version  # Warn early
  validate_before_start
  start
}
```

## Behavior

### Ephemeral Mode (default)
- The file `/opt/stellar/.docker-ephemeral` exists
- No version tracking occurs
- Function returns immediately

### Persistent Mode - First Run
- No `.quickstart-version` file exists
- Current `$REVISION` is saved to `/opt/stellar/.quickstart-version`
- No warning displayed

### Persistent Mode - Same Version
- Stored version matches current `$REVISION`
- No warning displayed

### Persistent Mode - Version Mismatch
- Stored version differs from current `$REVISION`
- Warning displayed with:
  - Both version numbers
  - Explanation of potential issues
  - Resolution options
  - Link to README documentation
- Stored version is updated to current version

## Example Warning Output

```
========================================================================
WARNING: Quickstart version mismatch detected!
========================================================================

  Stored version:  abc123def
  Current version: xyz789ghi

You are running a different version of quickstart than was previously
used with this persistent volume. This may cause issues because:

  - Configuration files in /opt/stellar may be outdated
  - Scripts may reference binaries that no longer exist
  - File formats or directory structures may have changed

To resolve this, you can:

  1. Start fresh: Remove the contents of your mounted volume and restart
  2. Pin the version: Use the same quickstart image version as before
  3. Update manually: Review and update configuration files as needed

For more information about persistent mode limitations, see:
  https://github.com/stellar/quickstart#persistent-mode

========================================================================
```

## Testing

1. **Ephemeral mode**: Ensure no version file is created when `.docker-ephemeral` exists
2. **First persistent run**: Verify version file is created
3. **Same version**: Verify no warning on subsequent run with same version
4. **Version change**: Modify stored version, restart, verify warning appears
