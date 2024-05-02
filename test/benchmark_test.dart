import 'package:isolate_manager/isolate_manager.dart';
import 'package:test/test.dart';

import 'isolate_manager_test.dart';

//  dart test
//  dart test --platform=vm "test/benchmark_test.dart"
//  dart test --platform=chrome "test/benchmark_test.dart"

void main() {
  test('Benchmark', () async {
    print('|Fibonacci|Main App|One Isolate|Three Isolates|Isolate.run|');
    print('|:-:|-:|-:|-:|-:|');

    // Fibonacci 30
    await execute(30);

    // Fibonacci 33
    await execute(33);

    // Fibonacci 36
    await execute(36);
  }, timeout: Timeout(Duration(seconds: 90)));
}

Future<void> execute(int fibonacciNumber) async {
  Duration singleInMain = Duration.zero;
  Duration singleInIsolate = Duration.zero;
  Duration threeIsolatesInIsolate = Duration.zero;
  Duration runMethodInIsolate = Duration.zero;

  // Main App
  final stopWatch = Stopwatch()..start();
  for (int i = 0; i < 70; i++) {
    fibonacciRecursive(fibonacciNumber);
  }
  singleInMain = stopWatch.elapsed;
  stopWatch
    ..stop()
    ..reset();

  // One Isolate (Worker)
  final singleIsolate = IsolateManager.create(
    fibonacciRecursive,
    workerName: 'fibonacci_recursive',
    autoInitialize: false,
  );
  await singleIsolate.start();
  stopWatch.start();
  for (int i = 0; i < 70; i++) {
    await singleIsolate.compute(fibonacciNumber);
  }
  singleInIsolate = stopWatch.elapsed;
  stopWatch
    ..stop()
    ..reset();

  // Three Isolates (Workers)
  final threeIsolates = IsolateManager.create(
    fibonacciRecursive,
    concurrent: 3,
    workerName: 'fibonacci_recursive',
    autoInitialize: false,
  );
  await threeIsolates.start();

  stopWatch.start();
  await Future.wait(
      [for (int i = 0; i < 70; i++) threeIsolates.compute(fibonacciNumber)]);
  threeIsolatesInIsolate = stopWatch.elapsed;
  stopWatch
    ..stop()
    ..reset();

  // Isolate.run
  // TODO: Readd this benchmark when updating the min sdk to `2.19.0`.
  // try {
  //   stopWatch.start();
  //   for (int i = 0; i < 70; i++) {
  //     await Isolate.run(() => fibonacciRecursive(fibonacciNumber));
  //   }
  //   runMethodInIsolate = stopWatch.elapsed;
  //   stopWatch
  //     ..stop()
  //     ..reset();
  // } on UnsupportedError catch (_) {
  //   /* Unsupported on the Web platform */
  // }

  print(
      '|$fibonacciNumber|${singleInMain.inMicroseconds}|${singleInIsolate.inMicroseconds}|${threeIsolatesInIsolate.inMicroseconds}|${runMethodInIsolate.inMicroseconds}|');
}
