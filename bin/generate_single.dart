import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:args/args.dart';
import 'package:isolate_manager/src/isolate_manager.dart';
import 'package:path/path.dart' as p;

import 'generate.dart';
import 'model/annotation_result.dart';

const String classAnnotation = 'IsolateManagerWorker';
const String constAnnotation = 'isolateManagerWorker';
const String constCustomWorkerAnnotation = 'isolateManagerCustomWorker';

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

  printDebug(
    () => 'Parsing the `IsolateManagerWorker` inside directory: $input...',
  );

  final dir = Directory(input);
  if (!dir.existsSync()) {
    printDebug(() => 'The command run in the wrong directory.');
    return;
  }

  final allFiles = _listAllFiles(Directory(input), <FileSystemEntity>[]);
  final isolateManager = IsolateManager<int, List<dynamic>>.create(
    _getAndGenerateFromAnotatedFunctions,
    concurrent: 3,
  )..start().ignore();

  final params = <List<dynamic>>[];
  for (final file in allFiles) {
    if (file is File && file.path.endsWith('.dart')) {
      final filePath = file.absolute.path;
      final content = await file.readAsString();
      final pattern = RegExp(
        '(@$classAnnotation|@$constAnnotation|@$constCustomWorkerAnnotation)',
      );
      if (content.contains(pattern)) {
        params.add(
          <dynamic>[filePath, obfuscate, isDebug, isWasm, output, dartArgs],
        );
      }
    }
  }

  printDebug(() => 'Total files to generate: ${params.length}');

  var counter = 0;
  await Future.wait(
    <Future<int>>[
      for (final param in params)
        isolateManager.compute(param).then((int value) => counter += value),
    ],
  );

  printDebug(() => 'Total generated functions: $counter');

  await isolateManager.stop();
  printDebug(() => 'Done');
}

Future<int> _getAndGenerateFromAnotatedFunctions(List<dynamic> params) async {
  final filePath = params[0] as String;
  final obfuscate = params[1] as String;
  final isDebug = params[2] as bool;
  final isWasm = params[3] as bool;
  final output = params[4] as String;
  final dartArgs = params[5] as List<String>;

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
    printDebug(() => 'Error resolving file.');
    return <String, AnnotationResult>{};
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
    <Future<void>>[
      for (final MapEntry<String, AnnotationResult> function
          in anotatedFunctions.entries)
        _generateFromAnotatedFunction(
          sourceFilePath,
          function,
          obfuscate,
          isDebug,
          isWasm,
          output,
          dartArgs,
        ),
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
  var inputPath = p.join(
    p.dirname(sourceFilePath),
    '.IsolateManagerWorker.${function.key}.${function.hashCode}.dart',
  );
  inputPath = p.absolute(inputPath);
  final file = File(inputPath);
  final sink = file.openWrite()
    ..writeln("import '${p.basename(sourceFilePath)}';")
    ..writeln("import 'package:isolate_manager/isolate_manager.dart';")
    ..writeln()
    ..writeln('main() {');
  if (function.value.isCustomWorker) {
    sink.writeln(
      '  IsolateManagerFunction.customWorkerFunction(${function.key});',
    );
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

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  final process = Process.run(
    'dart',
    <String>[
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
    process.asStream().listen((ProcessResult data) {
      printDebug(() => data.stdout);
    });
  }

  final result = await process;

  if (outputFile.existsSync()) {
    printDebug(
      () =>
          'Path: ${p.relative(sourceFilePath)} => Function: ${function.key} => '
          'Compiled: ${p.relative(outputPath)}',
    );
    if (!isDebug) {
      if (isWasm) {
        await File('$output/$name.unopt.wasm').delete();
      } else {
        await File('$output/$name.js.deps').delete();
      }
    }
  } else {
    printDebug(
      () =>
          'Path: ${p.relative(sourceFilePath)} => Function: ${function.key} => '
          'Compile ERROR: ${p.relative(outputPath)}',
    );
    final r = result.stdout.toString().split('\n');
    for (final element in r) {
      printDebug(() => '   > $element');
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
      final variable = annotationElement.variable2?.name;
      if (variable == constAnnotation) {
        return AnnotationResult(
          workerName: '',
          isCustomWorker: false,
        );
      } else if (variable == constCustomWorkerAnnotation) {
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
  final files = dir.listSync();
  var list = fileList;
  for (final file in files) {
    if (file is File) {
      list.add(file);
    } else if (file is Directory) {
      list = _listAllFiles(file, list);
    }
  }

  return list;
}
