import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:args/args.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:path/path.dart' as p;

const constAnnotation = 'isolateManagerSharedWorker';

void main(List<String> args) async {
  await generate(args);
}

/// --path "path/to/generate" --obfuscate 0->4 --debug
Future<void> generate(List<String> args) async {
  final parser = ArgParser()
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
      'obfuscate',
      valueHelp: '4',
      defaultsTo: '4',
      help: 'JS obfuscation level (0 to 4). Default is set to 4',
    )
    ..addOption(
      'name',
      abbr: 'n',
      valueHelp: kSharedWorkerName,
      defaultsTo: kSharedWorkerName,
      help: 'Name of the generated JS. Default is set to `$kSharedWorkerName`.',
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
  final input = argResult['input'] as String;
  final output = argResult['output'] as String;
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
  final name = argResult['name'] as String;

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
  )..start();

  List<List<dynamic>> params = [];
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

  Map<String, String> anotatedFunctions = {};
  int counter = 0;
  await Future.wait(
    [
      for (final param in params)
        isolateManager.compute(param).then((value) {
          counter += value.length;
          anotatedFunctions.addAll(value);
        })
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
    );
  }

  print('Total generated functions: $counter');

  await isolateManager.stop();
  print('Done');
}

Future<Map<String, String>> _getAndGenerateFromAnotatedFunctions(
    List<dynamic> params) async {
  String filePath = params[0];

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

  final result = await Process.run(
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
    ],
  );

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
