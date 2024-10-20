import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:args/args.dart';
import 'package:isolate_manager/src/isolate_manager.dart';
import 'package:path/path.dart' as p;

import 'model/annotation_result.dart';

const classAnnotation = 'IsolateManagerWorker';
const constAnnotation = 'isolateManagerWorker';
const constCustomWorkerAnnotation = 'isolateManagerCustomWorker';

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

  print('Parsing the `IsolateManagerWorker` inside directory: $input...');

  final dir = Directory(input);
  if (!dir.existsSync()) {
    print('The command run in the wrong directory.');
    return;
  }

  final allFiles = _listAllFiles(Directory(input), []);
  final isolateManager = IsolateManager.create(
    _getAndGenerateFromAnotatedFunctions,
    concurrent: 3,
  )..start();

  final params = <List<dynamic>>[];
  for (final file in allFiles) {
    if (file is File && file.path.endsWith('.dart')) {
      final filePath = file.absolute.path;
      final content = await file.readAsString();
      final pattern = RegExp(
          '(@$classAnnotation|@$constAnnotation|@$constCustomWorkerAnnotation)');
      if (content.contains(pattern)) {
        params.add([filePath, obfuscate, isDebug, isWasm, output, dartArgs]);
      }
    }
  }

  print('Total files to generate: ${params.length}');

  int counter = 0;
  await Future.wait(
    [
      for (final param in params)
        isolateManager.compute(param).then((value) => counter += value)
    ],
  );

  print('Total generated functions: $counter');

  await isolateManager.stop();
  print('Done');
}

Future<int> _getAndGenerateFromAnotatedFunctions(List<dynamic> params) async {
  final String filePath = params[0];
  final String obfuscate = params[1];
  final bool isDebug = params[2];
  final bool isWasm = params[3];
  final String output = params[4];
  final List<String> dartArgs = params[5];

  final anotatedFunctions = await _getAnotatedFunctions(filePath);

  if (anotatedFunctions.isNotEmpty) {
    await _generateFromAnotatedFunctions(
      filePath,
      anotatedFunctions,
      obfuscate,
      isDebug,
      isWasm,
      output,
      dartArgs,
    );
  }

  return anotatedFunctions.length;
}

Future<Map<String, AnnotationResult>> _getAnotatedFunctions(String path) async {
  final sourceFilePath = p.absolute(path);
  final result = await resolveFile2(path: sourceFilePath);

  if (result is! ResolvedUnitResult) {
    print('Error resolving file.');
    return {};
  }

  final unit = result.unit;
  final annotatedFunctions = <String, AnnotationResult>{};

  for (final declaration in unit.declarations) {
    if (declaration is FunctionDeclaration) {
      final element = declaration.declaredElement;
      if (element != null) {
        final annotationNameValue =
            getIsolateManagerWorkerAnnotationValue(element);
        if (annotationNameValue != null) {
          annotatedFunctions[element.name] = annotationNameValue;
        }
      }
    } else if (declaration is ClassDeclaration) {
      for (final member in declaration.members) {
        if (member is MethodDeclaration && member.isStatic) {
          final element = member.declaredElement;
          if (element != null) {
            final annotationNameValue =
                getIsolateManagerWorkerAnnotationValue(element);
            if (annotationNameValue != null) {
              annotatedFunctions['${declaration.name}.${element.name}'] =
                  annotationNameValue;
            }
          }
        }
      }
    }
  }

  return annotatedFunctions;
}

Future<void> _generateFromAnotatedFunctions(
  String sourceFilePath,
  Map<String, AnnotationResult> anotatedFunctions,
  String obfuscate,
  bool isDebug,
  bool isWasm,
  String output,
  List<String> dartArgs,
) async {
  await Future.wait(
    [
      for (final function in anotatedFunctions.entries)
        _generateFromAnotatedFunction(
          sourceFilePath,
          function,
          obfuscate,
          isDebug,
          isWasm,
          output,
          dartArgs,
        )
    ],
  );
}

Future<void> _generateFromAnotatedFunction(
  String sourceFilePath,
  MapEntry<String, AnnotationResult> function,
  String obfuscate,
  bool isDebug,
  bool isWasm,
  String output,
  List<String> dartArgs,
) async {
  String inputPath = p.join(
    p.dirname(sourceFilePath),
    '.IsolateManagerWorker.${function.key}.${function.hashCode}.dart',
  );
  inputPath = p.absolute(inputPath);
  final file = File(inputPath);
  final sink = file.openWrite();
  sink.writeln("import '${p.basename(sourceFilePath)}';");
  sink.writeln("import 'package:isolate_manager/isolate_manager.dart';");
  sink.writeln();
  sink.writeln('main() {');
  if (function.value.isCustomWorker) {
    sink.writeln(
        '  IsolateManagerFunction.customWorkerFunction(${function.key});');
  } else {
    sink.writeln('  IsolateManagerFunction.workerFunction(${function.key});');
  }
  sink.writeln('}');
  await sink.close();

  final extension = isWasm ? 'wasm' : 'js';

  final name = function.value.workerName != ''
      ? function.value.workerName
      : function.key;
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
      inputPath,
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
    print(
        'Path: ${p.relative(sourceFilePath)} => Function: ${function.key} => Compiled: ${p.relative(outputPath)}');
    if (!isDebug) {
      if (isWasm) {
        await File('$output/$name.unopt.wasm').delete();
      } else {
        await File('$output/$name.js.deps').delete();
      }
    }
  } else {
    print(
        'Path: ${p.relative(sourceFilePath)} => Function: ${function.key} => Compile ERROR: ${p.relative(outputPath)}');
    final r = result.stdout.toString().split('\n');
    for (var element in r) {
      print('   > $element');
    }
  }

  if (!isDebug) {
    await file.delete();
  }
}

AnnotationResult? getIsolateManagerWorkerAnnotationValue(Element element) {
  for (final metadata in element.metadata) {
    final annotationElement = metadata.element;
    if (annotationElement is ConstructorElement) {
      final enclosingElement = annotationElement.enclosingElement;
      if (enclosingElement is ClassElement &&
          enclosingElement.name == classAnnotation) {
        final annotation = metadata.computeConstantValue();
        final value = annotation?.getField('name')?.toStringValue();
        return AnnotationResult(
          workerName: value ?? '',
          isCustomWorker: false,
        );
      }
    } else if (annotationElement is PropertyAccessorElement) {
      // TODO: Change to `variable2` when bumping the `analyzer` to `^6.0.0`
      // ignore: deprecated_member_use
      final variable = annotationElement.variable;
      if (variable.name == constAnnotation) {
        return AnnotationResult(
          workerName: '',
          isCustomWorker: false,
        );
      } else if (variable.name == constCustomWorkerAnnotation) {
        return AnnotationResult(
          workerName: '',
          isCustomWorker: true,
        );
      }
    }
  }
  return null;
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
