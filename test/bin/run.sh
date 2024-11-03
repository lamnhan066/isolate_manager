#!/bin/bash

dart test --platform=chrome

dart run isolate_manager:generate -i test -o test --worker-mappings-experiment=test/isolate_manager_test.dart
dart run isolate_manager:generate -i test -o test --worker-mappings-experiment=test/isolate_manager_shared_test.dart
dart run isolate_manager:generate -i test -o test/workers

dart test --platform=chrome --coverage=coverage
dart test --platform=vm --coverage=coverage

dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib --check-ignore

sed -i 's|SF:.*/lib|SF:lib|' coverage/lcov.info
