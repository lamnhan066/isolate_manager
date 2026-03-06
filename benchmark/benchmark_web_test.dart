// For debug only
// ignore_for_file: avoid_print

@TestOn('chrome')
library;

import 'dart:async';
import 'dart:math';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:test/test.dart';

import 'functions.dart';
import 'utils.dart';

const samples = 30;

void main() {
  IsolateManager.addWorkerMapping(fibonacciRecursive, 'fibonacciRecursive');

  test('benchmark', () async {
    printDebug(
      () =>
          '|Fibonacci|Main App|One Isolate|Three Isolates|IsolateManager.runFunction|IsolateManager.run|Isolate.run (Unsupported)|',
    );
    printDebug(() => '|:-:|-:|-:|-:|-:|-:|-:|');

    await warmup(23);
    await warmup(26);
    await warmup(29);

    await benchmarkFor(23);
    await benchmarkFor(26);
    await benchmarkFor(29);
  }, timeout: const Timeout(Duration(seconds: 180)));
}

Future<void> warmup(int fibonacciNumber) async {
  final iterations = switch (fibonacciNumber) {
    23 => 20,
    26 => 10,
    29 => 5,
    _ => 10,
  };

  await execute(fibonacciNumber, iterations: iterations, warmupOnly: true);
}

Future<void> benchmarkFor(int fibonacciNumber) async {
  final iterations = switch (fibonacciNumber) {
    23 => 50,
    26 => 30,
    29 => 10,
    _ => 50,
  };

  final result = await execute(fibonacciNumber, iterations: iterations);
  printDebug(() => result);
}

Future<String> execute(
  int fibonacciNumber, {
  required int iterations,
  bool warmupOnly = false,
}) async {
  final results = <String, Duration>{};

  Future<Duration> measureStable(Future<void> Function() action) async {
    final values = <int>[];

    for (var i = 0; i < samples; i++) {
      await Future<void>.delayed(Duration.zero); // yield event loop

      final watch = Stopwatch()..start();
      await action();
      watch.stop();

      values.add(watch.elapsedMicroseconds);
    }

    values.sort();
    final median = values[values.length ~/ 2];

    return Duration(microseconds: median);
  }

  Future<void> runMainApp() async {
    for (var i = 0; i < iterations; i++) {
      fibonacciRecursive(fibonacciNumber);
    }
  }

  Future<void> runOneIsolate() async {
    final singleIsolate = IsolateManager<int, int>.create(fibonacciRecursive);

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
    );

    await threeIsolates.start();

    await Future.wait([
      for (int i = 0; i < iterations; i++)
        threeIsolates.compute(fibonacciNumber),
    ]);

    await threeIsolates.stop();
  }

  Future<void> runIsolateManagerFunction() async {
    for (var i = 0; i < iterations; i++) {
      await IsolateManager.runFunction(fibonacciRecursive, fibonacciNumber);
    }
  }

  Future<void> runIsolateManagerRun() async {
    for (var i = 0; i < iterations; i++) {
      await IsolateManager.run(
        () => fibonacciRecursive(fibonacciNumber),
        workerName: 'fibonacciRecursive',
        workerParameter: fibonacciNumber,
      );
    }
  }

  final tests = <String, Future<void> Function()>{
    'Main App': runMainApp,
    'One Isolate': runOneIsolate,
    'Three Isolates': runThreeIsolates,
    'IsolateManager.runFunction': runIsolateManagerFunction,
    'IsolateManager.run': runIsolateManagerRun,
  };

  if (warmupOnly) {
    for (final fn in tests.values) {
      await fn();
    }
    return '';
  }

  final entries = tests.entries.toList()..shuffle(Random());

  for (final entry in entries) {
    results[entry.key] = await measureStable(entry.value);
  }

  results['Isolate.run'] = Duration.zero;

  String format(Duration d) {
    final perIteration = d.inMicroseconds ~/ iterations;
    return perIteration.asThousands();
  }

  return '|$fibonacciNumber|'
      '${format(results['Main App']!)}|'
      '${format(results['One Isolate']!)}|'
      '${format(results['Three Isolates']!)}|'
      '${format(results['IsolateManager.runFunction']!)}|'
      '${format(results['IsolateManager.run']!)}|'
      '${format(results['Isolate.run']!)}|';
}

void printDebug(Object? Function() log) {
  print(log());
}
