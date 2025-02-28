// ignore_for_file: avoid_print

@TestOn('chrome')
library;

import 'package:isolate_manager/isolate_manager.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test(
    'benchmark',
    () async {
      printDebug(
        () =>
            '|Fibonacci|Main App|One Isolate|Three Isolates|IsolateManager.run|Isolate.run (Unsupported)|',
      );
      printDebug(() => '|:-:|-:|-:|-:|-:|-:|');

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

int fibonacciRecursive(int n) {
  if (n == 0) return 0;
  if (n == 1) return 1;

  return fibonacciRecursive(n - 1) + fibonacciRecursive(n - 2);
}

Future<void> execute(int fibonacciNumber) async {
  var singleInMain = Duration.zero;
  var singleInIsolate = Duration.zero;
  var threeIsolatesInIsolate = Duration.zero;
  var runMethodInIsolateManager = Duration.zero;

  // Main App
  final stopWatch = Stopwatch()..start();
  for (var i = 0; i < 70; i++) {
    fibonacciRecursive(fibonacciNumber);
  }
  singleInMain = stopWatch.elapsed;
  stopWatch
    ..stop()
    ..reset()
    ..start();

  // One Isolate (Worker)
  final singleIsolate = IsolateManager<int, int>.create(
    fibonacciRecursive,
    workerName: 'fibonacciRecursive',
  );
  await singleIsolate.start();
  for (var i = 0; i < 70; i++) {
    await singleIsolate.compute(fibonacciNumber);
  }
  singleInIsolate = stopWatch.elapsed;
  await singleIsolate.stop();
  stopWatch
    ..stop()
    ..reset()
    ..start();

  // Three Isolates (Workers)
  final threeIsolates = IsolateManager<int, int>.create(
    fibonacciRecursive,
    concurrent: 3,
    workerName: 'fibonacciRecursive',
  );

  await threeIsolates.start();
  await Future.wait(
    [for (int i = 0; i < 70; i++) threeIsolates.compute(fibonacciNumber)],
  );
  await threeIsolates.stop();
  threeIsolatesInIsolate = stopWatch.elapsed;

  stopWatch
    ..stop()
    ..reset()
    ..start();

  for (var i = 0; i < 70; i++) {
    await IsolateManager.run(
      () => fibonacciRecursive(fibonacciNumber),
      workerName: 'fibonacciRecursive',
      workerParameter: fibonacciNumber,
    );
  }
  runMethodInIsolateManager = stopWatch.elapsed;
  stopWatch
    ..stop()
    ..reset();

  printDebug(
    () => '|$fibonacciNumber|${singleInMain.inMicroseconds.asThousands}|'
        '${singleInIsolate.inMicroseconds.asThousands}|'
        '${threeIsolatesInIsolate.inMicroseconds.asThousands}|'
        '${runMethodInIsolateManager.inMicroseconds.asThousands}|-|',
  );
}

void printDebug(Object? Function() log) {
  print(log());
}
