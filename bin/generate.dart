import 'dart:io';

import 'package:args/args.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:path/path.dart';

import 'generate_shared.dart' as shared;
import 'generate_single.dart' as single;

void main(List<String> args) async {
  final separator = args.indexOf(' -- ');
  List<String> dartArgs = [];
  if (separator != -1) {
    dartArgs = args.sublist(separator + 1);
    args = args.sublist(0, separator);
  }

  final parser = ArgParser()
    ..addFlag(
      'single',
      defaultsTo: false,
      help: 'Generate the single Workers',
    )
    ..addFlag(
      'shared',
      defaultsTo: false,
      help: 'Generate the shared Workers',
    )
    ..addOption(
      'input',
      abbr: 'i',
      help:
          'Path of the folder to generate the Workers. Default is set to `lib`.',
      valueHelp: 'lib',
      defaultsTo: 'lib',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help:
          'Path of the folder to save the generated files. Default is set to `web`.',
      valueHelp: 'web',
      defaultsTo: 'web',
    )
    ..addOption(
      'name',
      abbr: 'n',
      valueHelp: kSharedWorkerName,
      defaultsTo: kSharedWorkerName,
      help: 'Name of the generated JS. Default is set to `$kSharedWorkerName`.',
    )
    ..addOption(
      'obfuscate',
      valueHelp: '4',
      defaultsTo: '4',
      help: 'JS obfuscation level (0 to 4). Default is set to 4',
    )
    ..addFlag(
      'debug',
      defaultsTo: false,
      help: 'Export the debug files like *.js.deps, *.js.map and *.unopt.wasm',
    )
    ..addFlag(
      'wasm',
      defaultsTo: false,
      help: 'Compile to wasm',
    )
    ..addOption(
      'worker-mappings-experiment',
      defaultsTo: '',
      help:
          '[Experiment] Generate the `workerMappings` and add it to the `main` app automatically',
    );

  final argResults = parser.parse(args);

  bool isSingle = argResults['single'] as bool;
  bool isShared = argResults['shared'] as bool;

  if (!isSingle && !isShared) {
    isSingle = true;
    isShared = true;
  }

  if (isSingle) {
    print('>> Generating the single Workers...');
    await single.generate(argResults, dartArgs);
    print('>> Generated.');
  }

  if (isShared) {
    print('>> Generating the shared Worker...');
    await shared.generate(argResults, dartArgs);
    print('>> Generated.');
  }
}

void printDebug(Object? Function() log) {
  print(log());
}

Future<void> addWorkerMappingToSourceFile(
  String workerMappingsPath,
  String sourceFilePath,
  String functionName,
) async {
  final mainPath = workerMappingsPath.isNotEmpty
      ? absolute(workerMappingsPath)
      : absolute('lib/main.dart');

  final file = File(mainPath);
  if (!file.existsSync()) {
    printDebug(() => 'Source file does not exist: $mainPath');
    return;
  }

  // Read the existing content of the file.
  final content = await file.readAsLines();

  // Step 1: Add the import statements.
  var lastImportIndex = -1;
  for (var i = 0; i < content.length; i++) {
    if (content[i].startsWith('import ')) {
      lastImportIndex = i;
    }
  }

  const newImportLine =
      "import 'package:isolate_manager/isolate_manager.dart';";
  // Insert the new import line after all existing import statements, if it doesn't exist already.
  if (!content.contains(newImportLine)) {
    content.insert(++lastImportIndex, newImportLine);
  }

  final newFunctionSourceImport =
      "import '${relative(sourceFilePath, from: 'lib')}';";
  if (absolute(sourceFilePath) != mainPath &&
      !content.contains(newFunctionSourceImport)) {
    content.insert(++lastImportIndex, newFunctionSourceImport);
  }

  // Step 2: Find the `main` function and add `addWorkerMappings();` at the beginning.
  var mainIndex = -1;
  for (var i = 0; i < content.length; i++) {
    if (content[i].contains('void main()')) {
      mainIndex = i;
      break;
    }
  }

  if (mainIndex == -1) {
    printDebug(() => 'No main function found in the source file.');
    return;
  }

  // Find the position after the opening brace of the `main` function.
  var insertionIndex = mainIndex;
  while (insertionIndex < content.length &&
      !content[insertionIndex].contains('{')) {
    insertionIndex++;
  }

  if (insertionIndex == content.length) {
    printDebug(() => 'Malformed main function, no opening brace found.');
    return;
  }

  // Add `addWorkerMappings();` if it doesn't already exist.
  const addWorkerMappingsCall = '  _addWorkerMappings();';
  var hasAddWorkerMappings = false;
  for (var i = insertionIndex; i < content.length; i++) {
    if (content[i].contains('_addWorkerMappings();')) {
      hasAddWorkerMappings = true;
      break;
    }
  }

  if (!hasAddWorkerMappings) {
    content.insert(insertionIndex + 1, addWorkerMappingsCall);
  }

  // Step 3: Collect `IsolateManager.addWorkerMapping` statements and move to `addWorkerMappings` function.
  final newWorkerMappingLine =
      "  IsolateManager.addWorkerMapping($functionName, '$functionName');";

  // Step 4: Add or update the `addWorkerMappings` function at the end of the file.
  final addWorkerMappingsIndex =
      content.indexWhere((line) => line.contains('void _addWorkerMappings()'));

  if (addWorkerMappingsIndex == -1) {
    // If `addWorkerMappings` function does not exist, add it at the end.
    content
      ..add('')
      ..add('/// This method MUST be stored at the end of the file to avoid')
      ..add('/// issues when generating.')
      ..add('void _addWorkerMappings() {')
      ..add(newWorkerMappingLine)
      ..add('}')
      ..add('');
  } else {
    // If `addWorkerMappings` already exists, add the new worker mapping if not already present.
    bool hasThisMapping = false;
    for (int i = addWorkerMappingsIndex; i < content.length; i++) {
      if (content[i].contains(RegExp('(\'$functionName\'|"$functionName")'))) {
        hasThisMapping = true;
        break;
      }
    }

    if (!hasThisMapping) {
      content.insert(addWorkerMappingsIndex + 1, newWorkerMappingLine);
    }
  }

  // Write the modified content back to the file.
  await file.writeAsString(content.join('\n'));

  printDebug(
    () =>
        'Updated source file: $sourceFilePath with new import, worker mapping call, and addWorkerMappings function.',
  );
}
