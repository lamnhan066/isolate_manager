// ignore_for_file: avoid_print

@TestOn('chrome')
library;

import 'dart:isolate';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test(
    'benchmark',
    () async {
      printDebug(
        () =>
            '|Fibonacci|Main App|One Isolate|Three Isolates|IsolateManager.runFunction|IsolateManager.run|Isolate.run (Unsupported)|',
      );
      printDebug(() => '|:-:|-:|-:|-:|-:|-:|-:|');

      // Warmup: run each part once to trigger JIT
      await warmup(30);
      await warmup(33);
      await warmup(36);

      // Run benchmarks
      await benchmarkFor(30);
      await benchmarkFor(33);
      await benchmarkFor(36);
    },
    timeout: const Timeout(Duration(seconds: 180)),
  );
}

/// Run one warmup round to reduce JIT overhead.
Future<void> warmup(int fibonacciNumber) async {
  await execute(fibonacciNumber, iterations: 5, warmupOnly: true);
}

/// Benchmark each method for the given fibonacci number.
Future<void> benchmarkFor(int fibonacciNumber) async {
  final result = await execute(fibonacciNumber, iterations: 70);
  printDebug(() => result);
}

/// Runs different methods with a separate measurement function.
/// If [warmupOnly] is set, no measurement will be taken.
Future<String> execute(
  int fibonacciNumber, {
  required int iterations,
  bool warmupOnly = false,
}) async {
  final results = <String, Duration>{};

  // Use a function to measure elapsed time for an async action.
  Future<Duration> measure(Future<void> Function() action) async {
    final watch = Stopwatch()..start();
    await action();
    watch.stop();
    return watch.elapsed;
  }

  Future<void> runMainApp() async {
    for (var i = 0; i < iterations; i++) {
      fibonacciRecursive(fibonacciNumber);
    }
  }

  Future<void> runOneIsolate() async {
    final singleIsolate = IsolateManager<int, int>.create(
      fibonacciRecursive,
      workerName: 'fibonacciRecursive',
    );
    await singleIsolate.start();
    for (var i = 0; i < iterations; i++) {
      await singleIsolate.compute(fibonacciNumber);
    }
    await singleIsolate.stop();
  }

  Future<void> runThreeIsolates() async {
    final threeIsolates = IsolateManager<int, int>.create(
      fibonacciRecursive,
      concurrent: 3,
      workerName: 'fibonacciRecursive',
    );
    await threeIsolates.start();
    await Future.wait(
      [
        for (int i = 0; i < iterations; i++)
          threeIsolates.compute(fibonacciNumber),
      ],
    );
    await threeIsolates.stop();
  }

  Future<void> runIsolateManagerFunction() async {
    for (var i = 0; i < iterations; i++) {
      await IsolateManager.runFunction(fibonacciRecursive, fibonacciNumber);
    }
  }

  Future<void> runIsolateManagerRun() async {
    for (var i = 0; i < iterations; i++) {
      await IsolateManager.run(() => fibonacciRecursive(fibonacciNumber));
    }
  }

  Future<void> runIsolateRun() async {
    for (var i = 0; i < iterations; i++) {
      await Isolate.run(() => fibonacciRecursive(fibonacciNumber));
    }
  }

  if (warmupOnly) {
    await runMainApp();
    await runOneIsolate();
    await runThreeIsolates();
    await runIsolateManagerFunction();
    await runIsolateManagerRun();
    await runIsolateRun();
    return '';
  }

  results['Main App'] = await measure(runMainApp);
  results['One Isolate'] = await measure(runOneIsolate);
  results['Three Isolates'] = await measure(runThreeIsolates);
  results['IsolateManager.runFunction'] =
      await measure(runIsolateManagerFunction);
  results['IsolateManager.run'] = await measure(runIsolateManagerRun);
  results['Isolate.run'] = Duration.zero;

  // Convert durations to average microseconds per iteration
  String format(Duration d) => d.inMicroseconds.asThousands();

  return '|$fibonacciNumber|${format(results['Main App']!)}|${format(results['One Isolate']!)}|${format(results['Three Isolates']!)}|${format(results['IsolateManager.runFunction']!)}|${format(results['IsolateManager.run']!)}|${format(results['Isolate.run']!)}|';
}

@isolateManagerWorker
int fibonacciRecursive(int n) {
  if (n == 0) return 0;
  if (n == 1) return 1;
  return fibonacciRecursive(n - 1) + fibonacciRecursive(n - 2);
}

void printDebug(Object? Function() log) {
  print(log());
}
