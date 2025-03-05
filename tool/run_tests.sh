#!/bin/bash

dart test --platform=chrome --compiler dart2js,dart2wasm

# Restore all backup .js to keep the original files
trap 'find . -type f -name "*.js.bak" -exec sh -c "mv \"\$0\" \"\${0%.bak}\"" {} \;' EXIT INT TERM

# Backup all .js by renaming to .js.bak
find . -type f -name "*.js" -exec mv {} {}.bak \;

dart run isolate_manager:generate -i test -o test --worker-mappings-experiment=test/isolate_manager_test.dart --obfuscate 0
dart run isolate_manager:generate -i test -o test --worker-mappings-experiment=test/isolate_manager_shared_test.dart --obfuscate 0
dart run isolate_manager:generate -i test -o test/workers --obfuscate 0

dart test --platform=chrome --compiler dart2js
dart test --platform=chrome --compiler dart2wasm
dart test --platform=vm

dart test --platform=vm,chrome --compiler dart2js,dart2wasm --coverage=coverage

dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib --check-ignore

# Rename the covered file paths to relative paths
sed -i '' 's|SF:.*/lib|SF:lib|' coverage/lcov.info
