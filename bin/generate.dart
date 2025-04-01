// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Executes the isolate manager generator with the provided arguments.
///
/// Takes a list of command-line arguments, processes them, and generates
/// the appropriate worker files based on the configuration.
///
/// Returns:
///   0: Success
///   1: Compilation error
///   2: Unable to resolve file
///   3: No main function found
///   4: Main function has no open braces
///   5: File not found
///
///   11: Could not find package `isolate_manager_generator` or file `isolate_manager_generator`
///
///   111: Unknown error
void main(List<String> args) async {
  if (args.contains('--add-generator')) {
    print('Adding isolate_manager_generator to dev dependencies...');

    final addProcess = await Process.run(
      'dart',
      ['pub', 'add', 'isolate_manager_generator', '--dev'],
    );

    if (addProcess.exitCode != 0) {
      print('Failed to add isolate_manager_generator: ${addProcess.stderr}');
      exit(1);
    }

    print('Added isolate_manager_generator to dev dependencies.');
  }

  final process = await Process.start(
    'dart',
    ['run', 'isolate_manager_generator', ...args],
  );

  process.stdout.transform(const Utf8Decoder()).listen(print);
  process.stderr.transform(const Utf8Decoder()).listen((e) {
    switch (e.trim()) {
      case 'Could not find package `isolate_manager_generator` or file `isolate_manager_generator`':
        print(
          'Please run `dart pub add isolate_manager_generator --dev` or '
          'add `isolate_manager_generator` to your dev dependencies '
          'before running the generator.',
        );
        exit(11);
      default:
        print(e);
    }
    exit(111);
  });

  exit(await process.exitCode);
}
