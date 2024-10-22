#!/bin/bash

# Check if SKIP_CRATE is set
if [ -z "$SKIP_CRATE" ]; then
  echo "No crate to skip. Running tarpaulin for all crates."
else
  echo "Skipping crate: $SKIP_CRATE"
fi

# Find all crates by looking for Cargo.toml files
for crate in $(find packages -name Cargo.toml -exec dirname {} \;); do
  CRATE_NAME=$(basename $crate)

  # Skip the crate if SKIP_CRATE is set and matches the current crate
  if [ -n "$SKIP_CRATE" ] && [ "$CRATE_NAME" = "$SKIP_CRATE" ]; then
    echo "Skipping tarpaulin for $CRATE_NAME"
    continue
  fi

  echo "Running coverage for crate: $CRATE_NAME"
  mkdir -p "$crate/tarpaulin_temp"
  mkdir -p "$crate/coverage"
  
  cargo tarpaulin --manifest-path $crate/Cargo.toml --out lcov \
    --output-dir $crate/coverage --exclude-files "/target/**/*" "/tarpaulin_temp/**/*" \
    --target-dir $crate/tarpaulin_temp --skip-clean || echo "Tarpaulin failed for $CRATE_NAME"
done
