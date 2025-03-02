import 'dart:async';
import 'dart:convert';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager/src/base/contactor/models/isolate_port.dart';
import 'package:isolate_manager/src/models/isolate_queue.dart';
import 'package:test/test.dart';

import '../test/isolate_manager_shared_test.dart';

/*
  dart run isolate_manager:generate -i test -o test --single --worker-mappings-experiment=test/isolate_manager_test.dart
  dart run isolate_manager:generate -i test -o test/workers --single --worker-mappings-experiment=test/isolate_manager_test.dart
  dart test --platform=vm
  dart test --platform=chrome
*/

void main() {
  _addWorkerMappings();

  group('Models', () {
    test('IsolateState', () {
      for (final state in IsolateState.values) {
        expect(state.isValidMap(state.toMap()), equals(true));
      }
    });

    test('IsolatePort', () {
      for (final port in IsolatePort.values) {
        expect(port, isA<IsolatePort>());
      }
    });

    test('IsolateException', () {
      final exception =
          IsolateException('Object', StackTrace.fromString('stackTrace'));
      final json = exception.toMap();
      expect(IsolateException.isValidMap(json), equals(true));
      expect(IsolateException.fromMap(json), isA<IsolateException>());
    });
  });

  group('IsolateManager.addWorkerMapping', () {
    setUp(IsolateManager.clearWorkerMappings);

    tearDown(() {
      IsolateManager.clearWorkerMappings();
      _addWorkerMappings();
    });

    test('should add a new function mapping', () {
      void testFunction(_) {}
      const workerName = 'testFunction';

      final isolate = IsolateManager.create(testFunction);
      expect(isolate.workerName, equals(''));

      IsolateManager.addWorkerMapping(testFunction, workerName);

      expect(isolate.workerName, equals(workerName));
    });

    test(
        'should throw an exception when adding a duplicate function without overwrite',
        () {
      void testFunction(_) {}
      const workerName = 'testFunction';

      IsolateManager.addWorkerMapping(testFunction, workerName);

      expect(
        () => IsolateManager.addWorkerMapping(testFunction, 'newWorker'),
        throwsA(isA<IsolateException>()),
      );

      // Ensure the mapping remains unchanged
      final isolate = IsolateManager.create(testFunction);
      expect(isolate.workerName, equals(workerName));
    });

    test('should overwrite an existing function mapping when overwrite is true',
        () {
      void testFunction(_) {}
      const oldWorkerName = 'testFunction';
      const newWorkerName = 'newWorker';

      IsolateManager.addWorkerMapping(testFunction, oldWorkerName);
      final isolate = IsolateManager.create(testFunction);

      expect(isolate.workerName, equals(oldWorkerName));

      IsolateManager.addWorkerMapping(
        testFunction,
        newWorkerName,
        overwrite: true,
      );

      expect(isolate.workerName, equals(newWorkerName));
    });
  });

  test('Test IsolateManager.create: Basic Usage', () async {
    // Create IsolateContactor
    final isolateManager = IsolateManager<int, int>.create(
      fibonacci,
      concurrent: 4,
      isDebug: true,
    );

    final result = await isolateManager.compute(3);

    expect(result, equals(fibonacci(3)));

    await isolateManager.stop();
  });

  test('Test IsolateManager.create: Basic Usage With Future', () async {
    // Create IsolateContactor
    final isolateManager = IsolateManager<int, int>.create(
      fibonacciFuture,
      concurrent: 4,
      isDebug: true,
    );

    final result = await isolateManager.compute(3);

    expect(result, equals(await fibonacciFuture(3)));

    await isolateManager.stop();
  });

  test('Test IsolateManager.create', () async {
    // Create IsolateContactor
    final isolateManager = IsolateManager<int, int>.create(
      fibonacci,
      concurrent: 4,
    );

    expect(isolateManager.isStarted, equals(false));

    await isolateManager.start();

    expect(isolateManager.isStarted, equals(true));
    await isolateManager.ensureStarted;

    expect(isolateManager.queuesLength, equals(0));

    await Future.wait(<Future<void>>[
      for (int i = 0; i < 10; i++)
        isolateManager.compute(i).then((int value) {
          expect(value, fibonacci(i));
        }),
    ]);

    await isolateManager.stop();
  });

  test('Test IsolateManager.create With Future', () async {
    // Create IsolateContactor
    final isolateManager = IsolateManager<int, int>.create(
      fibonacciFuture,
      concurrent: 4,
    );

    expect(isolateManager.isStarted, equals(false));

    await isolateManager.start();

    expect(isolateManager.isStarted, equals(true));
    await isolateManager.ensureStarted;

    expect(isolateManager.queuesLength, equals(0));

    await Future.wait(<Future<void>>[
      for (int i = 0; i < 10; i++)
        isolateManager.compute(i).then((int value) async {
          expect(value, equals(await fibonacciFuture(i)));
        }),
    ]);

    await isolateManager.stop();
  });

  test('Test IsolateManager.createCustom', () async {
    // Create IsolateContactor
    final isolateManager = IsolateManager<int, int>.createCustom(
      isolateFunction,
      concurrent: 4,
      initialParams: <String>['Test initialParams 0', 'Test initialParams 1'],
    )..start().ignore();

    isolateManager.stream
        .listen((int value) {})
        // Do not need to catch the error here
        .onError((error) {});

    await Future.wait(<Future<void>>[
      for (int i = 0; i < 10; i++)
        isolateManager.compute(i).then((int value) {
          expect(value, fibonacci(i));
        }),
    ]);

    await isolateManager.restart();

    await Future.wait(<Future<void>>[
      for (int i = 5; i < 13; i++)
        isolateManager.compute(i).then((int value) {
          expect(value, fibonacci(i));
        }),
    ]);

    await expectLater(() => isolateManager.sendMessage(-1), throwsStateError);
    await isolateManager.stop();
  });

  test('Test IsolateManager.createCustom with `null` initialParams', () async {
    // Create IsolateContactor
    final isolateManager = IsolateManager<int, int>.createCustom(
      isolateFunction,
    )..start().ignore();

    await expectLater(() => isolateManager(-1), throwsStateError);
    await isolateManager.stop();
  });

  test('Test IsolateManager.createCustom with automatically handlers',
      () async {
    // Create IsolateContactor
    final isolateManager = IsolateManager<int, int>.createCustom(
      isolateFunctionWithAutomaticallyHandlers,
      concurrent: 4,
      initialParams: <String>['Test initialParams 0', 'Test initialParams 1'],
    )..start().ignore();

    isolateManager.stream
        .listen((int value) {})
        // Do not need to catch the error here
        .onError((error) {});

    await Future.wait(<Future<void>>[
      for (int i = 0; i < 10; i++)
        isolateManager.compute(i).then((int value) {
          expect(value, fibonacci(i));
        }),
    ]);

    await isolateManager.restart();

    await Future.wait(<Future<void>>[
      for (int i = 5; i < 13; i++)
        isolateManager.compute(i).then((int value) {
          expect(value, fibonacci(i));
        }),
    ]);

    await expectLater(() => isolateManager.sendMessage(-1), throwsStateError);
    await isolateManager.stop();
  });

  test('Test with Exception future function', () async {
    final isolateManager = IsolateManager<int, List<int>>.create(
      errorFunctionFuture,
    );
    await isolateManager.start();

    await expectLater(
      () async => isolateManager.compute(<int>[50, 50]),
      throwsStateError,
    );
    await isolateManager.stop();
  });

  test('Test with Exception function', () async {
    final isolateManager = IsolateManager<int, List<int>>.create(
      errorFunction,
    );
    await isolateManager.start();

    await expectLater(
      () async => isolateManager.compute(<int>[50, 50]),
      throwsStateError,
    );
    await isolateManager.stop();
  });

  test('Test with Exception function with available callback', () async {
    final isolateManager = IsolateManager<int, List<int>>.create(
      errorFunction,
    );
    await isolateManager.start();

    await expectLater(
      () => isolateManager.compute(
        <int>[50, 50],
        callback: (int value) {
          return true;
        },
      ),
      throwsStateError,
    );
    await isolateManager.stop();
  });

  test('Test with Exception function with eagerError is true', () async {
    final isolateManager = IsolateManager<int, List<int>>.create(
      errorFunction,
      concurrent: 2,
    );
    await isolateManager.start();
    final futures = <Future<dynamic>>[];

    for (var i = 0; i < 100; i++) {
      futures.add(isolateManager.compute(<int>[i, 20]));
    }

    await expectLater(
      () async => Future.wait(futures, eagerError: true),
      throwsStateError,
    );
    await isolateManager.stop();
  });

  test(
      'Test with Exception function with eagerError is true with available callback',
      () async {
    final isolateManager = IsolateManager<int, List<int>>.create(
      errorFunction,
      concurrent: 2,
    );
    await isolateManager.start();
    final futures = <Future<dynamic>>[];

    for (var i = 0; i < 100; i++) {
      futures.add(
        isolateManager.compute(<int>[i, 20], callback: (int value) => true),
      );
    }

    await expectLater(
      () async => Future.wait(futures, eagerError: true),
      throwsStateError,
    );
    await isolateManager.stop();
  });

  test('Test with all Exception functions with eagerError is true', () async {
    final isolateManager = IsolateManager<int, List<int>>.create(
      errorFunction,
      concurrent: 2,
    );
    await isolateManager.start();
    final futures = <Future<dynamic>>[];

    for (var i = 0; i < 100; i++) {
      futures.add(isolateManager.compute(<int>[50, 20]));
    }

    await expectLater(
      () async => Future.wait(futures, eagerError: true),
      throwsStateError,
    );
    await isolateManager.stop();
  });

  test(
      'Test with all Exception functions with eagerError is true with available callback',
      () async {
    final isolateManager = IsolateManager<int, List<int>>.create(
      errorFunction,
      concurrent: 2,
    );
    await isolateManager.start();
    final futures = <Future<dynamic>>[];

    for (var i = 0; i < 100; i++) {
      futures.add(
        isolateManager.compute(<int>[50, 20], callback: (int value) => true),
      );
    }

    await expectLater(
      () async => Future.wait(futures, eagerError: true),
      throwsStateError,
    );
    await isolateManager.stop();
  });

  test('Test with Exception function with eagerError is false', () async {
    final isolateManager = IsolateManager<int, List<int>>.create(
      errorFunction,
      concurrent: 2,
    );
    await isolateManager.start();
    final futures = <Future<dynamic>>[];

    for (var i = 0; i < 100; i++) {
      futures.add(isolateManager.compute(<int>[i, 20]));
    }

    await expectLater(
      () async => Future.wait(futures),
      throwsStateError,
    );
    await isolateManager.stop();
  });

  test(
      'Test with Exception function with eagerError is false with available callback',
      () async {
    final isolateManager = IsolateManager<int, List<int>>.create(
      errorFunction,
      concurrent: 2,
    );
    await isolateManager.start();
    final futures = <Future<dynamic>>[];

    for (var i = 0; i < 100; i++) {
      futures.add(
        isolateManager.compute(<int>[i, 20], callback: (int value) => true),
      );
    }

    await expectLater(
      () async => Future.wait(futures),
      throwsStateError,
    );
    await isolateManager.stop();
  });

  test('Test with all Exception functions with eagerError is false', () async {
    final isolateManager = IsolateManager<int, List<int>>.create(
      errorFunction,
      concurrent: 2,
    );
    await isolateManager.start();
    final futures = <Future<dynamic>>[];

    for (var i = 0; i < 100; i++) {
      futures.add(isolateManager.compute(<int>[50, 20]));
    }

    await expectLater(
      () async => Future.wait(futures),
      throwsStateError,
    );
    await isolateManager.stop();
  });

  test(
      'Test with all Exception functions with eagerError is false with available callback',
      () async {
    final isolateManager = IsolateManager<int, List<int>>.create(
      errorFunction,
      concurrent: 2,
    );
    await isolateManager.start();
    final futures = <Future<dynamic>>[];

    for (var i = 0; i < 100; i++) {
      futures.add(
        isolateManager.compute(<int>[50, 20], callback: (int value) => true),
      );
    }

    await expectLater(
      () async => Future.wait(futures),
      throwsStateError,
    );
    await isolateManager.stop();
  });

  test('Test with IsolateCallback', () async {
    final isolateManager = IsolateManager<String, int>.createCustom(
      isolateCallbackFunction,
      workerName: 'workers/isolateCallbackFunction',
    );
    await isolateManager.start();

    final result = await isolateManager.compute(
      1,
      callback: (String value) {
        final decoded = jsonDecode(value) as Map;
        // Do not return this [value] as the final result
        if (decoded.containsKey('source')) {
          return false;
        }

        // Return this [value] as the final result
        return true;
      },
    );

    final decoded = jsonDecode(result) as Map;
    expect(
      decoded.containsKey('data'),
      equals(true),
    );

    await isolateManager.stop();
  });

  test('Test with IsolateCallback with simpler function', () async {
    final isolateManager = IsolateManager<String, int>.createCustom(
      isolateCallbackSimpleFunction,
      workerName: 'workers/isolateCallbackSimpleFunction',
    );
    await isolateManager.start();

    final result = await isolateManager.compute(
      1,
      callback: (String value) {
        final decoded = jsonDecode(value) as Map;
        // Do not return this [value] as the final result
        if (decoded.containsKey('source')) {
          return false;
        }

        // Return this [value] as the final result
        return true;
      },
    );

    final decoded = jsonDecode(result) as Map;
    expect(
      decoded.containsKey('data'),
      equals(true),
    );

    await isolateManager.stop();
  });

  test('Test with IsolateCallback with simpler specified type function',
      () async {
    final isolateManager = IsolateManager<String, int>.createCustom(
      isolateCallbackSimpleFunctionWithSpecifiedType,
    );
    await isolateManager.start();

    final result = await isolateManager.compute(
      1,
      callback: (String value) {
        final decoded = jsonDecode(value) as Map;
        // Do not return this [value] as the final result
        if (decoded.containsKey('source')) {
          return false;
        }

        // Return this [value] as the final result
        return true;
      },
    );

    final decoded = jsonDecode(result) as Map;
    expect(
      decoded.containsKey('data'),
      equals(true),
    );

    await isolateManager.stop();
  });

  test(
      'Test with IsolateCallback with simpler specified type function no Worker',
      () async {
    final isolateManager = IsolateManager<String, int>.createCustom(
      isolateCallbackSimpleFunctionWithSpecifiedType,
    );
    await isolateManager.start();

    final result = await isolateManager.compute(
      1,
      callback: (String value) {
        final decoded = jsonDecode(value) as Map;
        // Do not return this [value] as the final result
        if (decoded.containsKey('source')) {
          return false;
        }

        // Return this [value] as the final result
        return true;
      },
    );

    final decoded = jsonDecode(result) as Map;
    expect(
      decoded.containsKey('data'),
      equals(true),
    );

    await isolateManager.stop();
  });

  test('Test with returning a List<String>', () async {
    final isolate = IsolateManager.create(aStringList);
    await isolate.start();

    final listString = <String>['a', 'b', 'c'];
    final result = await isolate.compute(listString);

    expect(result, equals(listString));
  });

  test('Test with returning a real Map', () async {
    final isolate = IsolateManager.create(aDynamicMap);
    await isolate.start();

    final map = <String, Object>{'a': '1', 'b': 2, 'c': 3};
    final result = await isolate.compute(map);

    expect(result, equals(map));
  });

  test('Test a 2D List to 1D List', () async {
    final isolate = IsolateManager.create(a2DTo1DList);
    await isolate.start();

    final list = <List<String>>[
      <String>['a', 'b', 'v'],
      <String>['d', 'e', 'f'],
    ];
    final result = await isolate.compute(list);

    expect(result, equals(a2DTo1DList(list)));
  });

  test('Test a 1D List to 2D List', () async {
    final isolate = IsolateManager.create(a1DTo2DList);
    await isolate.start();

    final list = <String>['a', 'b', 'v', 'd', 'e', 'f'];
    final result = await isolate.compute(list);

    expect(result, equals(a1DTo2DList(list)));
  });

  group('Isolate Queue Strategy -', () {
    test('QueueStrategyRemoveNewest with unlimited queue count', () {
      final queueStrategies = QueueStrategyUnlimited<int, int>();
      for (var i = 0; i < 10; i++) {
        queueStrategies.add(IsolateQueue<int, int>(i, null));
      }
      expect(queueStrategies.queuesCount, equals(10));
      expect(queueStrategies.continueIfMaxCountExceeded(), true);
      final result = <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
      while (queueStrategies.hasNext()) {
        expect(queueStrategies.getNext().params, equals(result.removeAt(0)));
      }
      expect(result.length, equals(0));
    });

    test('QueueStrategyRemoveNewest with addToTop is true', () {
      final queueStrategies = QueueStrategyUnlimited<int, int>();
      for (var i = 0; i < 10; i++) {
        queueStrategies.add(IsolateQueue<int, int>(i, null), addToTop: true);
      }
      expect(queueStrategies.queuesCount, equals(10));
      final result = <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9].reversed.toList();
      while (queueStrategies.hasNext()) {
        expect(queueStrategies.getNext().params, equals(result.removeAt(0)));
      }
      expect(result.length, equals(0));
    });

    test('QueueStrategyRemoveNewest', () {
      final queueStrategies = QueueStrategyRemoveNewest<int, int>(maxCount: 3);
      for (var i = 0; i < 10; i++) {
        queueStrategies.add(IsolateQueue<int, int>(i, null));
      }
      expect(queueStrategies.queuesCount, equals(3));
      final result = <int>[0, 1, 9];
      while (queueStrategies.hasNext()) {
        expect(queueStrategies.getNext().params, equals(result.removeAt(0)));
      }
      expect(result.length, equals(0));
    });

    test('QueueStrategyRemoveNewest with addToTop is true', () {
      final queueStrategies = QueueStrategyRemoveNewest<int, int>(maxCount: 3);
      for (var i = 0; i < 10; i++) {
        queueStrategies.add(IsolateQueue<int, int>(i, null), addToTop: true);
      }
      expect(queueStrategies.queuesCount, equals(3));
      final result = <int>[9, 8, 7];
      while (queueStrategies.hasNext()) {
        expect(queueStrategies.getNext().params, equals(result.removeAt(0)));
      }
      expect(result.length, equals(0));
    });

    test('QueueStrategyRemoveOldest', () {
      final queueStrategies = QueueStrategyRemoveOldest<int, int>(maxCount: 3);
      for (var i = 0; i < 10; i++) {
        queueStrategies.add(IsolateQueue<int, int>(i, null));
      }
      expect(queueStrategies.queuesCount, equals(3));
      final result = <int>[7, 8, 9];
      while (queueStrategies.hasNext()) {
        expect(queueStrategies.getNext().params, equals(result.removeAt(0)));
      }
      expect(result.length, equals(0));
    });

    test('QueueStrategyRemoveOldest with addToTop is true', () {
      final queueStrategies = QueueStrategyRemoveOldest<int, int>(maxCount: 3);
      for (var i = 0; i < 10; i++) {
        queueStrategies.add(IsolateQueue<int, int>(i, null), addToTop: true);
      }
      expect(queueStrategies.queuesCount, equals(3));
      final result = <int>[9, 1, 0];
      while (queueStrategies.hasNext()) {
        expect(queueStrategies.getNext().params, equals(result.removeAt(0)));
      }
      expect(result.length, equals(0));
    });

    test('QueueStrategyDiscardIncoming', () {
      final queueStrategies =
          QueueStrategyDiscardIncoming<int, int>(maxCount: 3);
      for (var i = 0; i < 10; i++) {
        queueStrategies.add(IsolateQueue<int, int>(i, null));
      }
      expect(queueStrategies.queuesCount, equals(3));
      final result = <int>[0, 1, 2];
      while (queueStrategies.hasNext()) {
        expect(queueStrategies.getNext().params, equals(result.removeAt(0)));
      }
      expect(result.length, equals(0));
    });

    test('QueueStrategyDiscardIncoming with addToTop is true', () {
      final queueStrategies =
          QueueStrategyDiscardIncoming<int, int>(maxCount: 3);
      for (var i = 0; i < 10; i++) {
        queueStrategies.add(IsolateQueue<int, int>(i, null), addToTop: true);
      }
      expect(queueStrategies.queuesCount, equals(3));
      final result = <int>[2, 1, 0];
      while (queueStrategies.hasNext()) {
        expect(queueStrategies.getNext().params, equals(result.removeAt(0)));
      }
      expect(result.length, equals(0));
    });
  });

  group('Isolate Types -', () {
    test('num', () async {
      final isolates = IsolateManager.create(isolateTypeNum, isDebug: true);

      const value = IsolateNum(15);

      final result = await isolates.compute(value);

      expect(result, isA<IsolateNum>());
      expect(result, equals(value));
    });

    test('String', () async {
      const value = IsolateString('abc');
      final isolates = IsolateManager.create(isolateTypeString);

      final result = await isolates.compute(value);

      expect(result, isA<IsolateString>());
      expect(result, equals(value));
    });

    test('bool', () async {
      const value = IsolateBool(false);
      final isolates = IsolateManager.create(isolateTypeBool);

      final result = await isolates.compute(value);

      expect(result, isA<IsolateBool>());
      expect(result, equals(value));
    });

    test('List', () async {
      const value = IsolateList(<IsolateNum>[IsolateNum(100)]);
      final isolates = IsolateManager.create(isolateTypeList);

      final result = await isolates.compute(value);

      expect(result, isA<IsolateList>());
      expect(
        result,
        equals(const IsolateList(<IsolateString>[IsolateString('100')])),
      );
    });

    test('Map', () async {
      final isolates = IsolateManager.create(isolateTypeMap);
      final result = await isolates.compute(
        const IsolateList([IsolateNum(5), IsolateNum(7)]),
      );

      expect(result, isA<IsolateMap>());
      expect(
        result,
        equals(
          IsolateMap(<IsolateString, IsolateNum>{
            const IsolateString('5'): const IsolateNum(5),
            const IsolateString('7'): const IsolateNum(7),
          }),
        ),
      );
    });

    test('Nullable type', () async {
      final isolates = IsolateManager.create(isolateNullableInt);
      final result = await isolates(null);

      expect(result, equals(null));
    });
  });

  test('IsolateManager.run method', () async {
    final result = await IsolateManager.run(
      () => fibonacciRecursive(20),
      workerName: 'fibonacciRecursive',
      workerParameter: 20,
    );

    expect(result, equals(6765));
  });

  test('IsolateManager.runFunction method', () async {
    final result = await IsolateManager.runFunction(
      fibonacciRecursive,
      20,
    );

    expect(result, equals(6765));
  });
}

@isolateManagerWorker
int fibonacci(int n) {
  if (n < 0) throw StateError('n<0');
  if (n == 0) return 0;
  if (n == 1) return 1;

  var f1 = 0;
  var f2 = 1;
  var r = 1;

  for (var i = 2; i <= n; i++) {
    r = f1 + f2;
    f1 = f2;
    f2 = r;
  }

  return r;
}

@isolateManagerWorker
Future<int> fibonacciFuture(int n) async {
  if (n < 0) throw StateError('n<0');
  if (n == 0) return 0;
  if (n == 1) return 1;

  var f1 = 0;
  var f2 = 1;
  var r = 1;

  for (var i = 2; i <= n; i++) {
    r = f1 + f2;
    f1 = f2;
    f2 = r;
  }

  return r;
}

@isolateManagerWorker
int fibonacciRecursive(int n) {
  if (n == 0) return 0;
  if (n == 1) return 1;

  return fibonacciRecursive(n - 1) + fibonacciRecursive(n - 2);
}

@isolateManagerWorker
List<dynamic> aStringList(List<dynamic> params) {
  return params;
}

@isolateManagerWorker
Map<dynamic, dynamic> aDynamicMap(Map<dynamic, dynamic> params) {
  return params;
}

@isolateManagerWorker
List<dynamic> a2DTo1DList(List<dynamic> params) {
  return params.map((e) => (e as List).join()).toList();
}

@isolateManagerWorker
List<dynamic> a1DTo2DList(List<dynamic> params) {
  final result = <List<dynamic>>[<dynamic>[], <dynamic>[]];
  for (var i = 0; i < params.length; i++) {
    if (i.isEven) {
      result[0].add(params[i]);
    } else {
      result[1].add(params[i]);
    }
  }
  return result;
}

Future<void> isolateFunction(dynamic params) async {
  await IsolateManagerFunction.customFunction<int, int>(
    params,
    onEvent: (IsolateManagerController<int, int> controller, int message) {
      try {
        final result = fibonacci(message);
        controller.sendResult(result);
      } catch (err, stack) {
        controller.sendResultError(IsolateException(err, stack));
      }
      return 0;
    },
    onInit: (IsolateManagerController<int, int> controller) {},
    onDispose: (IsolateManagerController<int, int> controller) {},
    autoHandleException: false,
    autoHandleResult: false,
  );
}

@pragma('vm:entry-point')
void isolateFunctionWithAutomaticallyHandlers(dynamic params) {
  IsolateManagerFunction.customFunction<int, int>(
    params,
    onEvent: (IsolateManagerController<int, int> controller, int message) {
      return fibonacci(message);
    },
    onInit: (IsolateManagerController<int, int> controller) {},
    onDispose: (IsolateManagerController<int, int> controller) {},
  );
}

@isolateManagerCustomWorker
void isolateCallbackFunction(dynamic params) {
  IsolateManagerFunction.customFunction(
    params,
    onEvent: (
      IsolateManagerController<Object?, Object?> controller,
      Object? message,
    ) {
      try {
        for (var i = 0; i < 10; i++) {
          controller.sendResult(jsonEncode(<String, String>{'source': '$i'}));
        }

        controller.sendResult(jsonEncode(<String, String>{'data': 'data'}));
      } catch (err, stack) {
        controller.sendResultError(IsolateException(err, stack));
      }

      // Just returns something that unused to complete this method.
      return '';
    },
    autoHandleException: false,
    autoHandleResult: false,
  );
}

@isolateManagerCustomWorker
void isolateCallbackSimpleFunction(dynamic params) {
  IsolateManagerFunction.customFunction(
    params,
    onEvent: (
      IsolateManagerController<Object?, Object?> controller,
      Object? message,
    ) {
      for (var i = 0; i < 10; i++) {
        controller.sendResult(jsonEncode(<String, String>{'source': '$i'}));
      }

      return jsonEncode(<String, Object?>{'data': message});
    },
  );
}

@isolateManagerCustomWorker
void isolateCallbackSimpleFunctionWithSpecifiedType(dynamic params) {
  IsolateManagerFunction.customFunction<String, int>(
    params,
    onEvent: (IsolateManagerController<String, int> controller, int message) {
      for (var i = 0; i < 10; i++) {
        controller.sendResult(jsonEncode(<String, String>{'source': '$i'}));
      }

      return jsonEncode(<String, int>{'data': message});
    },
  );
}

@isolateManagerWorker
IsolateNum isolateTypeNum(IsolateNum number) {
  return IsolateNum(number.decode);
}

@isolateManagerWorker
IsolateString isolateTypeString(IsolateString string) {
  return IsolateString(string.decode);
}

@isolateManagerWorker
IsolateBool isolateTypeBool(IsolateBool boolean) {
  return IsolateBool(boolean.decode);
}

@isolateManagerWorker
IsolateList isolateTypeList(IsolateList numbers) {
  return IsolateList(numbers.decode!.map((e) => IsolateString('$e')).toList());
}

@isolateManagerWorker
IsolateMap isolateTypeMap(IsolateList numbers) {
  return IsolateMap(
    Map.fromEntries(
      numbers.decode!.map(
        (e) => MapEntry(IsolateString('$e'), IsolateNum(e! as num)),
      ),
    ),
  );
}

@isolateManagerWorker
int? isolateNullableInt(int? number) {
  return number;
}

@pragma('vm:entry-point')
int errorFunction(List<int> value) {
  if (value[0] == 50) {
    return throw StateError('The exception is threw at value[0] = ${value[0]}');
  }
  return value[0] + value[1];
}

@pragma('vm:entry-point')
Future<int> errorFunctionFuture(List<int> value) async {
  await Future<void>.delayed(const Duration(seconds: 1));

  if (value[0] == 50) {
    return throw StateError('The exception is threw at value[0] = ${value[0]}');
  }
  return value[0] + value[1];
}

void _addWorkerMappings() {
  IsolateManager.addWorkerMapping(isolateNullableInt, 'isolateNullableInt');
  IsolateManager.addWorkerMapping(isolateTypeString, 'isolateTypeString');
  IsolateManager.addWorkerMapping(isolateTypeBool, 'isolateTypeBool');
  IsolateManager.addWorkerMapping(isolateTypeList, 'isolateTypeList');
  IsolateManager.addWorkerMapping(isolateTypeMap, 'isolateTypeMap');
  IsolateManager.addWorkerMapping(isolateTypeNum, 'isolateTypeNum');
  IsolateManager.addWorkerMapping(complexReturn, 'complexReturn');
  IsolateManager.addWorkerMapping(concat, 'concat');
  IsolateManager.addWorkerMapping(addException, 'addException');
  IsolateManager.addWorkerMapping(add, 'add');
  IsolateManager.addWorkerMapping(addFuture, 'addFuture');
  IsolateManager.addWorkerMapping(a2DTo1DList, 'a2DTo1DList');
  IsolateManager.addWorkerMapping(a1DTo2DList, 'a1DTo2DList');
  IsolateManager.addWorkerMapping(aDynamicMap, 'aDynamicMap');
  IsolateManager.addWorkerMapping(aStringList, 'aStringList');
  IsolateManager.addWorkerMapping(
    isolateCallbackSimpleFunctionWithSpecifiedType,
    'isolateCallbackSimpleFunctionWithSpecifiedType',
  );
  IsolateManager.addWorkerMapping(
    isolateCallbackFunction,
    'isolateCallbackFunction',
  );
  IsolateManager.addWorkerMapping(
    isolateCallbackSimpleFunction,
    'isolateCallbackSimpleFunction',
  );
  IsolateManager.addWorkerMapping(fibonacci, 'fibonacci');
  IsolateManager.addWorkerMapping(fibonacciRecursive, 'fibonacciRecursive');
  IsolateManager.addWorkerMapping(fibonacciFuture, 'fibonacciFuture');
}
