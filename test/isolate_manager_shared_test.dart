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
      // subPath: 'workers',
      isDebug: true,
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
      for (var i = 0; i < 10; i++)
        isolates.compute(
          addFuture,
          <double>[i.toDouble(), i.toDouble()],
        ).then(
          (double value) async {
            expect(
              value,
              equals(await addFuture(<double>[i.toDouble(), i.toDouble()])),
            );
          },
        ),
      for (var i = 0; i < 10; i++)
        isolates(add, <int>[i, i]).then(
          (int value) {
            expect(value, equals(add(<int>[i, i])));
          },
        ),
      for (var i = 0; i < 10; i++)
        isolates.compute(concat, <String>['$i', '$i']).then(
          (String value) {
            expect(value, equals(concat(<String>['$i', '$i'])));
          },
        ),
    ]);

    // Stop the usolate after 5 seconds
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
      for (var i = 0; i < 10; i++)
        isolates.compute(addFuture, <double>[i.toDouble(), i.toDouble()]).then(
          (double value) async {
            expect(
              value,
              equals(await addFuture(<double>[i.toDouble(), i.toDouble()])),
            );
          },
        ),
      for (var i = 0; i < 10; i++)
        isolates(add, <int>[i, i]).then(
          (int value) {
            expect(value, equals(add(<int>[i, i])));
          },
        ),
      for (var i = 0; i < 10; i++)
        isolates.compute(concat, <String>['$i', '$i']).then((String value) {
          expect(value, equals(concat(<String>['$i', '$i'])));
        }),
      isolates.compute(aDynamicMap, <String, Object>{'k': 1, 't': '2'}).then(
          (Map<dynamic, dynamic> value) {
        expect(value, equals(<String, Object>{'k': 1, 't': '2'}));
      }),
    ]);

    // Stop the usolate after 5 seconds
    await isolates.stop();
  });

  test('test try-catch', () async {
    // Create 3 isolates to solve the problems
    final isolates = IsolateManager.createShared();

    await expectLater(
      () async => isolates.compute(addException, <int>[1, 1]),
      throwsException,
    );

    // Stop the usolate after 5 seconds
    await isolates.stop();
  });

  // This test will work better if the `autoInitialized` is set to `false`.
  test('Ensure started', () async {
    // The first `compute` will ensure started automatically
    final isolates1 = IsolateManager.createShared(
      useWorker: true,
      subPath: 'workers',
      isDebug: true,
    );

    final stopWatch = Stopwatch()..start();
    expect(isolates1.isStarted, equals(false));
    await isolates1.compute(addFuture, <double>[2, 3]);
    final stopWithoutEnsured = stopWatch.elapsedMicroseconds;

    // reset stopwatch
    stopWatch
      ..stop()
      ..reset();

    // Calling the `compute` method after waiting for `ensureStarted`.
    final isolates2 = IsolateManager.createShared(useWorker: true);
    await isolates2.ensureStarted;
    expect(isolates1.isStarted, equals(true));

    stopWatch.start();
    await isolates2.compute(addFuture, <double>[2, 3]);
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
        <String>['abc'],
      ],
    );

    await isolates.restart();

    expect(result, isA<List<List<String>>>());
    expect(
      result,
      equals(<List<String>>[
        <String>['abc'],
      ]),
    );

    await isolates.stop();
  });

  test('Test `workerFunction`', () {
    try {
      IsolateManagerFunction.sharedWorkerFunction(<String, Function>{});
    } catch (e) {
      expect(e, isA<UnimplementedError>());
    }
  });

  test('Nullable type', () async {
    final isolates = IsolateManager.createShared(useWorker: true);
    final result = await isolates.compute(isolateNullableInt, null);

    expect(result, equals(null));
  });

  test('`useWorker` is `true` but `workerFunction` is not provided', () async {
    final isolates = IsolateManager.createShared(
      useWorker: true,
      isDebug: true,
    );

    expect(
      await isolates.compute(addWithoutWorker, <int>[2, 3]),
      equals(5),
    );
  });
}

int addWithoutWorker(List<int> params) => params[0] + params[1];

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
  return throw Exception('Has Exception');
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
Map<dynamic, dynamic> aDynamicMap(Map<dynamic, dynamic> params) {
  return params;
}

@isolateManagerSharedWorker
int? isolateNullableInt(int? number) {
  return number;
}

void _addWorkerMappings() {
  IsolateManager.addWorkerMapping(isolateNullableInt, 'isolateNullableInt');
  IsolateManager.addWorkerMapping(a1DTo2DList, 'a1DTo2DList');
  IsolateManager.addWorkerMapping(aStringList, 'aStringList');
  IsolateManager.addWorkerMapping(
    isolateCallbackFunction,
    'isolateCallbackFunction',
  );
  IsolateManager.addWorkerMapping(a2DTo1DList, 'a2DTo1DList');
  IsolateManager.addWorkerMapping(
    isolateCallbackSimpleFunction,
    'isolateCallbackSimpleFunction',
  );
  IsolateManager.addWorkerMapping(fibonacciRecursive, 'fibonacciRecursive');
  IsolateManager.addWorkerMapping(fibonacciFuture, 'fibonacciFuture');
  IsolateManager.addWorkerMapping(fibonacci, 'fibonacci');
  IsolateManager.addWorkerMapping(
    isolateCallbackSimpleFunctionWithSpecifiedType,
    'isolateCallbackSimpleFunctionWithSpecifiedType',
  );
  IsolateManager.addWorkerMapping(addFuture, 'addFuture');
  IsolateManager.addWorkerMapping(add, 'add');
  IsolateManager.addWorkerMapping(addException, 'addException');
  IsolateManager.addWorkerMapping(concat, 'concat');
  IsolateManager.addWorkerMapping(complexReturn, 'complexReturn');
  IsolateManager.addWorkerMapping(aDynamicMap, 'aDynamicMap');
}
