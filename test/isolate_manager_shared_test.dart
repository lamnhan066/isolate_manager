import 'dart:async';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:test/test.dart';

import '../test/isolate_manager_test.dart';

/*
  dart run isolate_manager:generate -i test -o test --shared --worker-mappings-experiment=test/isolate_manager_shared_test.dart
  dart run isolate_manager:generate -i test -o test/workers --shared --worker-mappings-experiment=test/isolate_manager_shared_test.dart
  dart test --platform=vm
  dart test --platform=chrome
*/

void main() async {
  _addWorkerMappings();
  test('test', () async {
    // Create 3 isolates to solve the problems
    final isolates = IsolateManager.createShared(
      concurrent: 3,
      useWorker: true,
      subPath: 'workers',
    );

    isolates.stream.listen((result) {
      if (result is double) {
        // print('Stream get addFuture: $result');
      } else if (result is String) {
        // print('Stream get concat: $result');
      } else {
        // print('Stream get add: $result');
      }
    });

    await Future.wait([
      for (double i = 0; i < 10; i++)
        isolates.compute(addFuture, [i, i]).then((value) async {
          expect(value, equals(await addFuture([i, i])));
        }),
      for (int i = 0; i < 10; i++)
        isolates(add, [i, i]).then((value) {
          expect(value, equals(add([i, i])));
        }),
      for (int i = 0; i < 10; i++)
        isolates.compute(concat, ['$i', '$i']).then((value) {
          expect(value, equals(concat(['$i', '$i'])));
        })
    ]);

    // Stop the isolates
    await isolates.stop();
  });

  test('Test with worker mappings', () async {
    // Create 3 isolates to solve the problems
    final isolates = IsolateManager.createShared(
      concurrent: 3,
      useWorker: true,
      subPath: 'workers',
    );

    isolates.stream.listen((result) {
      if (result is double) {
        // print('Stream get addFuture: $result');
      } else if (result is String) {
        // print('Stream get concat: $result');
      } else {
        // print('Stream get add: $result');
      }
    });

    await Future.wait([
      for (double i = 0; i < 10; i++)
        isolates.compute(addFuture, [i, i]).then((value) async {
          expect(value, equals(await addFuture([i, i])));
        }),
      for (int i = 0; i < 10; i++)
        isolates(add, [i, i]).then((value) {
          expect(value, equals(add([i, i])));
        }),
      for (int i = 0; i < 10; i++)
        isolates.compute(concat, ['$i', '$i']).then((value) {
          expect(value, equals(concat(['$i', '$i'])));
        }),
      isolates.compute(aDynamicMap, {'k': 1, 't': '2'}).then((value) {
        expect(value, equals({'k': 1, 't': '2'}));
      }),
    ]);

    // Stop the isolates
    await isolates.stop();
  });

  test('test try-catch', () async {
    // Create 3 isolates to solve the problems
    final isolates =
        IsolateManager.createShared(concurrent: 3, useWorker: true);

    // Catch the error from the stream
    isolates.stream.listen((result) {
      // print('Stream get add: $result');
    }).onError((Object e) {
      // print('Error from stream: $e');
      expect(e.toString(), equals(ArgumentError().toString()));
    });

    // Catch the error from the try-catch block
    try {
      await isolates.compute(
        addException,
        [1, 1],
      );
    } catch (e) {
      // print('Error from try-catch: $e');
      expect(e.toString(), equals(ArgumentError().toString()));
    }

    // Stop the isolate after 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    await isolates.stop();
  });

  // This test will work better if the `autoInitialized` is set to `false`.
  test('Ensure started', () async {
    // The first `compute` will ensure started automatically
    final isolates1 = IsolateManager.createShared(
      concurrent: 1,
      useWorker: true,
      subPath: 'workers',
    );

    final stopWatch = Stopwatch()..start();
    expect(isolates1.isStarted, equals(false));
    await isolates1.compute(addFuture, [2.0, 3.0]);
    final stopWithoutEnsured = stopWatch.elapsedMicroseconds;

    // reset stopwatch
    stopWatch
      ..stop()
      ..reset();

    // Calling the `compute` method after waiting for `ensureStarted`.
    final isolates2 =
        IsolateManager.createShared(concurrent: 1, useWorker: true);
    await isolates2.ensureStarted;
    expect(isolates1.isStarted, equals(true));

    stopWatch.start();
    await isolates2.compute(addFuture, [2.0, 3.0]);
    final stopWithEnsured = stopWatch.elapsedMicroseconds;
    stopWatch.stop();

    await isolates1.stop();
    await isolates2.stop();

    // The stopWithoutEnsured will always greater than the stopWithEnsured
    // because it needs to wait for the `ensureStarted` before computation.
    expect(stopWithoutEnsured, greaterThan(stopWithEnsured));
  });

  test('Complex return', () async {
    final isolates = IsolateManager.createShared();

    final result = await isolates.compute(
      complexReturn,
      <List<String>>[
        <String>['abc']
      ],
    );

    await isolates.restart();

    expect(result, isA<List<List<String>>>());
    expect(
        result,
        equals(<List<String>>[
          <String>['abc']
        ]));

    isolates.stop();
  });

  test('Test `workerFunction`', () {
    try {
      IsolateManagerFunction.sharedWorkerFunction({});
    } catch (e) {
      expect(e, isA<UnimplementedError>());
    }
  });
}

@isolateManagerSharedWorker
Future<double> addFuture(List<double> values) async {
  return values[0] + values[1];
}

@isolateManagerSharedWorker
int add(List<int> values) {
  return values[0] + values[1];
}

@isolateManagerSharedWorker
int addException(dynamic values) {
  return throw ArgumentError();
}

@isolateManagerSharedWorker
String concat(List<String> params) {
  return '${params[0]} ${params[1]}';
}

@isolateManagerSharedWorker
List<List<String>> complexReturn(List<List<String>> params) {
  return params;
}

@isolateManagerSharedWorker
Map aDynamicMap(Map params) {
  return params;
}

void _addWorkerMappings() {
  IsolateManager.addWorkerMapping(fibonacciRecursive, 'fibonacciRecursive');
  IsolateManager.addWorkerMapping(aStringList, 'aStringList');
  IsolateManager.addWorkerMapping(fibonacci, 'fibonacci');
  IsolateManager.addWorkerMapping(aDynamicMap, 'aDynamicMap');
  IsolateManager.addWorkerMapping(complexReturn, 'complexReturn');
  IsolateManager.addWorkerMapping(concat, 'concat');
  IsolateManager.addWorkerMapping(addException, 'addException');
  IsolateManager.addWorkerMapping(add, 'add');
  IsolateManager.addWorkerMapping(addFuture, 'addFuture');
  IsolateManager.addWorkerMapping(
      isolateCallbackSimpleFunctionWithSpecifiedType,
      'isolateCallbackSimpleFunctionWithSpecifiedType');
  IsolateManager.addWorkerMapping(
      isolateCallbackSimpleFunction, 'isolateCallbackSimpleFunction');
  IsolateManager.addWorkerMapping(a2DTo1DList, 'a2DTo1DList');
  IsolateManager.addWorkerMapping(
      isolateCallbackFunction, 'isolateCallbackFunction');
  IsolateManager.addWorkerMapping(aDynamicMap, 'aDynamicMap');
  IsolateManager.addWorkerMapping(a1DTo2DList, 'a1DTo2DList');
}
