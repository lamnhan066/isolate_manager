#!/bin/bash

dart test --platform=chrome

# Backup all .js by renaming to .js.bak
find . -type f -name "*.js" -exec mv {} {}.bak \;

dart run isolate_manager:generate -i test -o test --worker-mappings-experiment=test/isolate_manager_test.dart
dart run isolate_manager:generate -i test -o test --worker-mappings-experiment=test/isolate_manager_shared_test.dart
dart run isolate_manager:generate -i test -o test/workers

dart test --platform=chrome --coverage=coverage
dart test --platform=vm --coverage=coverage

dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib --check-ignore

# Rename the covered file paths to relative paths
sed -i '' 's|SF:.*/lib|SF:lib|' coverage/lcov.info

# Restore all backup .js to keep the original files
find . -type f -name "*.js.bak" -exec sh -c 'mv "$0" "${0%.bak}"' {} \;
