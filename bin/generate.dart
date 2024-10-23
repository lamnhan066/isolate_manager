import 'package:args/args.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager/src/utils/print.dart';

import 'generate_shared.dart' as shared;
import 'generate_single.dart' as single;

void main(List<String> paramArgs) async {
  var args = paramArgs;
  final separator = args.indexOf('--');
  var dartArgs = <String>[];
  if (separator != -1) {
    dartArgs = args.sublist(separator + 1);
    args = args.sublist(0, separator);
  }

  final parser = ArgParser()
    ..addFlag(
      'single',
      help: 'Generate the single Workers',
    )
    ..addFlag(
      'shared',
      help: 'Generate the shared Workers',
    )
    ..addOption(
      'input',
      abbr: 'i',
      help: 'Path of the folder to generate the Workers. '
          'Default is set to `lib`.',
      valueHelp: 'lib',
      defaultsTo: 'lib',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Path of the folder to save the generated files. '
          'Default is set to `web`.',
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
      help: 'Export the debug files like *.js.deps, *.js.map and *.unopt.wasm',
    )
    ..addFlag(
      'wasm',
      help: 'Compile to wasm',
    );

  final argResults = parser.parse(args);

  var isSingle = argResults['single'] as bool;
  var isShared = argResults['shared'] as bool;

  if (!isSingle && !isShared) {
    isSingle = true;
    isShared = true;
  }

  if (isSingle) {
    printDebug(() => '>> Generating the single Workers...');
    await single.generate(argResults, dartArgs);
    printDebug(() => '>> Generated.');
  }

  if (isShared) {
    printDebug(() => '>> Generating the shared Worker...');
    await shared.generate(argResults, dartArgs);
    printDebug(() => '>> Generated.');
  }
}

void printDebug(Object? Function() log) {
  debugPrinter(log, debug: true);
}
