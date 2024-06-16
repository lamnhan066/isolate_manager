import 'package:args/args.dart';
import 'package:isolate_manager/isolate_manager.dart';

import 'generate_shared.dart' as shared;
import 'generate_single.dart' as single;

void main(List<String> args) async {
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
    await single.generate(argResults);
    print('>> Generated.');
  }

  if (isShared) {
    print('>> Generating the shared Worker...');
    await shared.generate(argResults);
    print('>> Generated.');
  }
}
