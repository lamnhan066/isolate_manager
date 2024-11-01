import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:args/args.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:path/path.dart' as p;

import 'generate.dart';

const constAnnotation = 'isolateManagerSharedWorker';

/// --path "path/to/generate" --obfuscate 0->4 --debug
Future<void> generate(ArgResults argResults, List<String> dartArgs) async {
  final input = argResults['input'] as String;
  final output = argResults['output'] as String;
  final obfuscate = switch (argResults['obfuscate']) {
    '0' => '-O0',
    '1' => '-O1',
    '2' => '-O2',
    '3' => '-O3',
    '4' => '-O4',
    _ => '-O4',
  };
  final isDebug = argResults['debug'] as bool? ?? false;
  final isWasm = argResults['wasm'] as bool? ?? false;
  final name = argResults['name'] as String;
  final isWorkerMappings = argResults['worker-mappings-experiment'] as String;

  print('Parsing the `IsolateManagerWorker` inside directory: $input...');

  final dir = Directory(input);
  if (!dir.existsSync()) {
    print('The command run in the wrong directory.');
    return;
  }

  final List<FileSystemEntity> allFiles = _listAllFiles(Directory(input), []);
  final isolateManager = IsolateManager.create(
    _getAndGenerateFromAnotatedFunctions,
    concurrent: 3,
  );
  await isolateManager.start();

  final params = <List<dynamic>>[];
  for (final file in allFiles) {
    if (file is File && file.path.endsWith('.dart')) {
      final filePath = file.absolute.path;
      final content = await file.readAsString();
      final pattern = RegExp('@$constAnnotation');
      if (content.contains(pattern)) {
        params.add([filePath]);
      }
    }
  }

  print('Total files to generate: ${params.length}');

  final anotatedFunctions = <String, String>{};
  int counter = 0;
  await Future.wait(
    [
      for (final param in params)
        isolateManager.compute(param).then((value) {
          counter += value.length;
          anotatedFunctions.addAll(value);
        }),
    ],
  );

  if (anotatedFunctions.isNotEmpty) {
    await _generateFromAnotatedFunctions(
      anotatedFunctions,
      obfuscate,
      isDebug,
      isWasm,
      output,
      name,
      dartArgs,
      isWorkerMappings,
    );
  }

  print('Total generated functions: $counter');

  await isolateManager.stop();
  print('Done');
}

Future<Map<String, String>> _getAndGenerateFromAnotatedFunctions(
  List<dynamic> params,
) async {
  final String filePath = params[0];

  return _getAnotatedFunctions(filePath);
}

Future<Map<String, String>> _getAnotatedFunctions(String path) async {
  final sourceFilePath = p.absolute(path);
  final result = await resolveFile2(path: sourceFilePath);

  if (result is! ResolvedUnitResult) {
    print('Error resolving file.');
    return {};
  }

  final unit = result.unit;
  final annotatedFunctions = <String, String>{};

  for (final declaration in unit.declarations) {
    if (declaration is FunctionDeclaration) {
      final element = declaration.declaredElement;
      if (element != null) {
        final isValidAnnotation = checkAnnotation(element);
        if (isValidAnnotation) {
          annotatedFunctions[element.name] = p.relative(sourceFilePath);
        }
      }
    } else if (declaration is ClassDeclaration) {
      for (final member in declaration.members) {
        if (member is MethodDeclaration && member.isStatic) {
          final element = member.declaredElement;
          if (element != null) {
            final isValidAnnotation = checkAnnotation(element);
            if (isValidAnnotation) {
              annotatedFunctions['${declaration.name}.${element.name}'] =
                  p.relative(sourceFilePath);
            }
          }
        }
      }
    }
  }

  return annotatedFunctions;
}

Future<void> _generateFromAnotatedFunctions(
  Map<String, String> anotatedFunctions,
  String obfuscate,
  bool isDebug,
  bool isWasm,
  String output,
  String name,
  List<String> dartArgs,
  String workerMappingsPath,
) async {
  final file = File('.IsolateManagerShared.${anotatedFunctions.hashCode}.dart');
  final sink = file.openWrite();
  sink.writeln("import 'package:isolate_manager/isolate_manager.dart';");
  for (final function in anotatedFunctions.entries) {
    sink.writeln("import '${p.relative(function.value)}';");
  }
  sink.writeln('final Map<String, Function> map = {');
  for (final function in anotatedFunctions.entries) {
    sink.writeln("'${function.key}' : ${function.key},");
  }
  sink.writeln('};');
  sink.writeln('main() {');
  sink.writeln('  IsolateManagerFunction.sharedWorkerFunction(map);');
  sink.writeln('}');
  await sink.close();

  final extension = isWasm ? 'wasm' : 'js';

  final outputPath = p.join(output, '$name.$extension');
  final outputFile = File(outputPath);

  if (await outputFile.exists()) {
    await outputFile.delete();
  }

  final process = Process.run(
    'dart',
    [
      'compile',
      extension,
      file.path,
      '-o',
      outputPath,
      obfuscate,
      if (!isWasm) '--omit-implicit-checks',
      if (!isDebug && !isWasm) '--no-source-maps',
      ...dartArgs,
    ],
  );

  if (isDebug) {
    process.asStream().listen((data) {
      print(data.stdout);
    });
  }

  final result = await process;

  if (await outputFile.exists()) {
    print('Compiled: ${p.relative(outputPath)}');
    if (!isDebug) {
      if (isWasm) {
        await File('$output/$name.unopt.wasm').delete();
      } else {
        await File('$output/$name.js.deps').delete();
      }
    }
  } else {
    print('Compile ERROR: ${p.relative(outputPath)}');
    final r = result.stdout.toString().split('\n');
    for (var element in r) {
      print('   > $element');
    }
  }

  if (workerMappingsPath.isNotEmpty) {
    printDebug(() => 'Generate the `workerMappings`...');
    for (final function in anotatedFunctions.entries) {
      await addWorkerMappingToSourceFile(
        workerMappingsPath,
        p.absolute(function.value),
        function.key,
      );
    }
    printDebug(() => 'Done.');
  }

  if (!isDebug) {
    await file.delete();
  }
}

bool checkAnnotation(Element element) {
  for (final metadata in element.metadata) {
    final annotationElement = metadata.element;
    if (annotationElement is PropertyAccessorElement) {
      // TODO: Change to `variable2` when bumping the `analyzer` to `^6.0.0`
      // ignore: deprecated_member_use
      final variable = annotationElement.variable;
      if (variable.name == constAnnotation) {
        return true;
      }
    }
  }
  return false;
}

List<FileSystemEntity> _listAllFiles(
  Directory dir,
  List<FileSystemEntity> fileList,
) {
  final files = dir.listSync(recursive: false);

  for (FileSystemEntity file in files) {
    if (file is File) {
      fileList.add(file);
    } else if (file is Directory) {
      fileList = _listAllFiles(file, fileList);
    }
  }

  return fileList;
}
