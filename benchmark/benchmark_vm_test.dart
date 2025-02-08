@TestOn('vm')
library;

import 'dart:isolate';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager/src/utils/print.dart';
import 'package:test/test.dart';

import '../test/isolate_manager_test.dart';

void main() {
  test(
    'benchmark',
    () async {
      printDebug(
        () => '|Fibonacci|Main App|One Isolate|Three Isolates|Isolate.run|',
      );
      printDebug(() => '|:-:|-:|-:|-:|-:|');

      // Fibonacci 30
      await execute(30);

      // Fibonacci 33
      await execute(33);

      // Fibonacci 36
      await execute(36);
    },
    timeout: const Timeout(Duration(seconds: 120)),
  );
}

Future<void> execute(int fibonacciNumber) async {
  var singleInMain = Duration.zero;
  var singleInIsolate = Duration.zero;
  var threeIsolatesInIsolate = Duration.zero;
  var runMethodInIsolate = Duration.zero;

  // Main App
  final stopWatch = Stopwatch()..start();
  for (var i = 0; i < 70; i++) {
    fibonacciRecursive(fibonacciNumber);
  }
  singleInMain = stopWatch.elapsed;
  stopWatch
    ..stop()
    ..reset();

  // One Isolate (Worker)
  final singleIsolate = IsolateManager<int, int>.create(
    fibonacciRecursive,
    workerName: 'fibonacciRecursive',
  );

  stopWatch.start();
  await singleIsolate.start();
  for (var i = 0; i < 70; i++) {
    await singleIsolate.compute(fibonacciNumber);
  }
  singleInIsolate = stopWatch.elapsed;
  stopWatch
    ..stop()
    ..reset();

  // Three Isolates (Workers)
  final threeIsolates = IsolateManager<int, int>.create(
    fibonacciRecursive,
    concurrent: 3,
    workerName: 'fibonacciRecursive',
  );

  stopWatch.start();
  await threeIsolates.start();
  await Future.wait(
    [for (int i = 0; i < 70; i++) threeIsolates.compute(fibonacciNumber)],
  );
  threeIsolatesInIsolate = stopWatch.elapsed;
  stopWatch
    ..stop()
    ..reset()
    ..start();

  // Isolate.run
  for (var i = 0; i < 70; i++) {
    await Isolate.run(() => fibonacciRecursive(fibonacciNumber));
  }
  runMethodInIsolate = stopWatch.elapsed;
  stopWatch
    ..stop()
    ..reset();

  printDebug(
    () => '|$fibonacciNumber|${singleInMain.inMicroseconds}|'
        '${singleInIsolate.inMicroseconds}|${threeIsolatesInIsolate.inMicroseconds}'
        '|${runMethodInIsolate.inMicroseconds}|',
  );
}

void printDebug(Object? Function() log) {
  debugPrinter(log, debug: true);
}
