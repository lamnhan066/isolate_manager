import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:args/args.dart';
import 'package:isolate_manager/src/isolate_manager.dart';
import 'package:path/path.dart' as p;

const classAnnotation = 'IsolateManagerWorker';
const constAnnotation = 'isolateManagerWorker';

void main(List<String> args) async {
  await generate(args);
}

/// --path "path/to/generate" --obfuscate 0->4 --debug
Future<void> generate(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'path',
      abbr: 'p',
      help:
          'Path to the main folder that you want to to generate the Workers. Default is set to `lib`.',
      valueHelp: 'lib',
      defaultsTo: 'lib',
    )
    ..addOption(
      'obfuscate',
      valueHelp: '2',
      defaultsTo: '2',
      help: 'JS obfuscation level (0 to 4). Default is set to 2',
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
    );
  final argResult = parser.parse(args);
  final path = argResult['path'] as String;
  final obfuscate = switch (argResult['obfuscate']) {
    '0' => '-O0',
    '1' => '-O1',
    '2' => '-O2',
    '3' => '-O3',
    '4' => '-O4',
    _ => '-O2',
  };
  final isDebug = argResult['debug'] as bool? ?? false;
  final isWasm = argResult['wasm'] as bool? ?? false;

  print('Parsing the `IsolateManagerWorker` inside directory: $path...');

  final dir = Directory(path);
  if (!dir.existsSync()) {
    print('The command run in the wrong directory.');
    return;
  }

  final List<FileSystemEntity> allFiles = _listAllFiles(Directory(path), []);
  final isolateManager = IsolateManager.create(
    _getAndGenerateFromAnotatedFunctions,
    concurrent: 3,
  )..start();

  List<List<dynamic>> params = [];
  for (final file in allFiles) {
    if (file is File && file.path.endsWith('.dart')) {
      final filePath = file.absolute.path;
      final content = await file.readAsString();
      final pattern = RegExp('(@$classAnnotation|@$constAnnotation)');
      if (content.contains(pattern)) {
        params.add([filePath, obfuscate, isDebug, isWasm]);
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
  String filePath = params[0];
  String obfuscate = params[1];
  bool isDebug = params[2];
  bool isWasm = params[3];

  final anotatedFunctions = await _getAnotatedFunctions(filePath);

  if (anotatedFunctions.isNotEmpty) {
    await _generateFromAnotatedFunctions(
      filePath,
      anotatedFunctions,
      obfuscate,
      isDebug,
      isWasm,
    );
  }

  return anotatedFunctions.length;
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
  Map<String, String> anotatedFunctions,
  String obfuscate,
  bool isDebug,
  bool isWasm,
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
        )
    ],
  );
}

Future<void> _generateFromAnotatedFunction(
  String sourceFilePath,
  MapEntry<String, String> function,
  String obfuscate,
  bool isDebug,
  bool isWasm,
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
  sink.writeln('  IsolateManagerFunction.workerFunction(${function.key});');
  sink.writeln('}');
  await sink.close();

  final extension = isWasm ? 'wasm' : 'js';

  final name = function.value != '' ? function.value : function.key;
  final output = File('web/$name.$extension');

  if (await output.exists()) {
    await output.delete();
  }

  final result = await Process.run(
    'dart',
    [
      'compile',
      extension,
      inputPath,
      '-o',
      p.join('web', '$name.$extension'),
      obfuscate,
    ],
  );

  if (await File('web/$name.$extension').exists()) {
    print(
        'Path: ${p.relative(sourceFilePath)} => Function: ${function.key} => Compiled: web/$name.$extension');
    if (!isDebug) {
      if (isWasm) {
        await File('web/$name.unopt.wasm').delete();
      } else {
        await File('web/$name.js.deps').delete();
        await File('web/$name.js.map').delete();
      }
    }
  } else {
    print(
        'Path: ${p.relative(sourceFilePath)} => Function: ${function.key} => Compile ERROR: web/$name.$extension');
    final r = result.stdout.toString().split('\n');
    for (var element in r) {
      print('   > $element');
    }
  }

  await file.delete();
}

String? getIsolateManagerWorkerAnnotationValue(Element element) {
  for (final metadata in element.metadata) {
    final annotationElement = metadata.element;
    if (annotationElement is ConstructorElement) {
      final enclosingElement = annotationElement.enclosingElement;
      if (enclosingElement is ClassElement &&
          enclosingElement.name == classAnnotation) {
        final annotation = metadata.computeConstantValue();
        final value = annotation?.getField('name')?.toStringValue();
        return value;
      }
    } else if (annotationElement is PropertyAccessorElement) {
      // TODO: Change to `variable2` when bumping the `analyzer` to `^6.0.0`
      // ignore: deprecated_member_use
      final variable = annotationElement.variable;
      if (variable.name == constAnnotation) {
        return '';
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
