#!/bin/bash

# exist the script if any command fails
set -e

# Check if SKIP_CRATE is set
if [ -z "$SKIP_CRATE" ]; then
  echo "No crate to skip. Running tarpaulin for all crates."
else
  echo "Skipping crate: $SKIP_CRATE"
fi

# install coveralls to upload coverage
curl -L https://coveralls.io/coveralls-linux.tar.gz | sudo tar -xz -C /usr/local/bin

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
    --target-dir $crate/tarpaulin_temp --skip-clean 
    
  # Check if the coverage report exists and upload it
  if [ -f "$crate/coverage/lcov.info" ]; then
    echo "Uploading coverage for $CRATE_NAME"
    coveralls report "$crate/coverage/lcov.info" --repo-token $COVERALLS_REPO_TOKEN
  else
    echo "No lcov.info file found for $CRATE_NAME"
  fi

  # Append badge link to temp_readme_coverage.md
  echo "[![Coverage Status](https://coveralls.io/repos/github/Meta-A/bpm/${CRATE_NAME}/badge.svg?branch=main)](https://coveralls.io/github/Meta-A/bpm/${CRATE_NAME}?branch=main)" >> temp_readme_coverage.md
done

# Insert the generated coverage badges into README.md
if grep -q "# Code Coverage" README.md; then
  # Replace the old Code Coverage section
  sed -i '/# Code Coverage/,$d' README.md
fi

# Append the new coverage section to README.md
cat temp_readme_coverage.md >> README.md
rm temp_readme_coverage.md

# Optionally push the updated README.md back to the repository
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add README.md
git commit -m "Update code coverage badges for crates"
git push origin HEAD