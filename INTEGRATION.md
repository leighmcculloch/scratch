# Quickstart Version Persistence - Integration Guide

This document describes how to integrate the version persistence feature into the Stellar Quickstart container.

## Problem

When using persistent mode (volume mounted at `/opt/stellar`), users may upgrade the quickstart container but the mounted volume retains old configuration and scripts from a previous version. This can cause failures, such as when `soroban-rpc` was renamed to `stellar-rpc` and persisted scripts still referenced the old binary name.

See: https://github.com/stellar/quickstart/issues/762

## Solution

Persist the quickstart version (docker tag) and revision (git commit) in `/opt/stellar/.quickstart-version` and compare on startup. If versions differ, display a warning with actionable guidance including the exact docker tag to use for pinning.

## Integration Steps

### 1. Add VERSION build arg to the Dockerfile

Add a `VERSION` build argument that captures the docker tag:

```dockerfile
ARG PROTOCOL_VERSION_DEFAULT
ARG REVISION
ARG VERSION
ENV VERSION=${VERSION}
```

When building the image, pass the version:

```bash
docker build --build-arg VERSION=v1.2.3 --build-arg REVISION=$(git rev-parse HEAD) ...
```

### 2. Add the version check function to the `start` script

Add the contents of `start-version-check.sh` to the `start` script, placing the function definition near the other utility functions.

### 3. Call the function during startup

In the `start()` function, call `check_quickstart_version` after `copy_defaults`:

```bash
function start() {
  # ... existing code ...

  copy_defaults
  check_quickstart_version  # Add this line

  # ... rest of function ...
}
```

### 4. Alternative: Call early in main()

For earlier detection, call it in `main()` before the full startup:

```bash
function main() {
  process_args $*
  check_quickstart_version  # Warn early
  validate_before_start
  start
}
```

## Version File Format

The `.quickstart-version` file stores two lines:
1. VERSION - The docker tag (e.g., `v1.2.3`)
2. REVISION - The git commit hash (e.g., `abc123def`)

Example contents:
```
v1.2.3
abc123def456789
```

## Behavior

### Ephemeral Mode (default)
- The file `/opt/stellar/.docker-ephemeral` exists
- No version tracking occurs
- Function returns immediately

### Persistent Mode - First Run
- No `.quickstart-version` file exists
- Current `$VERSION` and `$REVISION` are saved to `/opt/stellar/.quickstart-version`
- No warning displayed

### Persistent Mode - Same Version
- Persistent revision matches current `$REVISION`
- No warning displayed

### Persistent Mode - Version Mismatch
- Persistent revision differs from current `$REVISION`
- Warning displayed with:
  - Both version tags and revisions
  - Explanation of potential issues
  - Exact docker command to pin to the previous version
  - Link to README documentation
- Persistent version is updated to current version

## Example Warning Output

```
========================================================================
WARNING: Quickstart version mismatch detected!
========================================================================

  Persistent version: v1.2.3 (abc123def)
  Current version:    v1.3.0 (xyz789ghi)

You are running a different version of quickstart than was previously
used with this persistent volume. This may cause issues because:

  - Configuration files in /opt/stellar may be outdated
  - Scripts may reference binaries that no longer exist
  - File formats or directory structures may have changed

To resolve this, you can:

  1. Start fresh: Remove the contents of your mounted volume and restart

  2. Pin the version: Use the same quickstart image version as before:

     docker run -v "/path/to/volume:/opt/stellar" stellar/quickstart:v1.2.3

  3. Update manually: Review and update configuration files as needed

For more information about persistent mode limitations, see:
  https://github.com/stellar/quickstart#persistent-mode

========================================================================
```

## Testing

1. **Ephemeral mode**: Ensure no version file is created when `.docker-ephemeral` exists
2. **First persistent run**: Verify version file is created with both VERSION and REVISION
3. **Same version**: Verify no warning on subsequent run with same revision
4. **Version change**: Modify persistent version file, restart, verify warning appears with correct docker tag
