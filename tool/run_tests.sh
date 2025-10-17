#!/bin/bash

dart test --platform=chrome --compiler dart2js,dart2wasm

# Restore all backup .js to keep the original files
trap 'find ./test/workers/ -type f -name "*.js.bak" -exec sh -c "mv \"\$0\" \"\${0%.bak}\"" {} \;' EXIT INT TERM

# Backup all .js by renaming to .js.bak
find ./test/workers/ -type f -name "*.js" -exec mv {} {}.bak \;

dart run isolate_manager:generate --add-generator -i test -o test/workers --single --sub-dir workers --worker-mappings-experiment=test/isolate_manager_test.dart --obfuscate 0
dart run isolate_manager:generate --add-generator -i test -o test/workers --shared --sub-dir workers --worker-mappings-experiment=test/isolate_manager_shared_test.dart --obfuscate 0

dart test --platform=vm,chrome --compiler dart2js,dart2wasm --coverage=coverage

dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib --check-ignore

# Rename the covered file paths to relative paths
sed -i '' 's|SF:.*/lib|SF:lib|' coverage/lcov.info
