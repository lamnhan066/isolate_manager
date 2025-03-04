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

  group('IsolateType - ', () {
    group('IsolateType.wrap', () {
      test('wraps num as IsolateNum', () {
        const numValue = 42;
        final encoded = IsolateType.wrap(numValue);
        expect(encoded, isA<IsolateNum>());
        expect((encoded as IsolateNum).unwrap, equals(numValue));
        expect(encoded.toDouble(), equals(numValue.toDouble()));
        expect(encoded.toInt(), equals(numValue));
      });

      test('can convert IsolateNum from different number types', () {
        // Integer test
        final intIsolate = IsolateType.wrap(10) as IsolateNum;
        expect(intIsolate.toInt(), equals(10));
        expect(intIsolate.toDouble(), equals(10.0));

        // Double test
        final doubleIsolate = IsolateType.wrap(10.5) as IsolateNum;
        expect(doubleIsolate.toInt(), equals(10));
        expect(doubleIsolate.toDouble(), equals(10.5));
      });

      test('wraps String as IsolateString', () {
        const strValue = 'Hello, Isolate!';
        final encoded = IsolateType.wrap(strValue);
        expect(encoded, isA<IsolateString>());
        expect((encoded as IsolateString).unwrap, equals(strValue));
      });

      test('wraps bool as IsolateBool', () {
        const boolValue = true;
        final encoded = IsolateType.wrap(boolValue);
        expect(encoded, isA<IsolateBool>());
        expect((encoded as IsolateBool).unwrap, equals(boolValue));
      });

      test('wraps List as IsolateList and can decode iterable', () {
        final listValue = [1, 'two', false];
        final encoded = IsolateType.wrap(listValue);
        expect(encoded, isA<IsolateList>());
        final isolateList = encoded as IsolateList;
        final wrappedList = isolateList.toList<IsolateType>();
        expect(wrappedList, isNotNull);
        // Test that each element is wrapped accordingly.
        expect(wrappedList[0], isA<IsolateNum>());
        expect(wrappedList[1], isA<IsolateString>());
        expect(wrappedList[2], isA<IsolateBool>());
        // Test decoded value.
        final decoded = isolateList.unwrap;
        expect(decoded, equals(listValue));
      });

      test('wraps Map as IsolateMap and can decode map', () {
        final mapValue = {
          'a': 1,
          'b': false,
          'c': 'three',
        };
        final encoded = IsolateType.wrap(mapValue);
        expect(encoded, isA<IsolateMap>());
        final isolateMap = encoded as IsolateMap;
        // Test that toMap returns a map with proper key/value types.
        final wrappedMap = isolateMap.toMap<IsolateString, IsolateType>();
        expect(wrappedMap, isA<Map<IsolateString, IsolateType>>());
        // Since keys are encoded, we check the decoded map.
        final decoded = isolateMap.unwrap;
        expect(decoded, equals(mapValue));
      });

      test('throws UnimplementedError for unsupported types', () {
        final unsupportedValue = DateTime.now();
        expect(
          () => IsolateType.wrap(unsupportedValue),
          throwsA(isA<UnimplementedError>()),
        );
      });
    });

    group('IsolateList helper methods', () {
      test('toIterable and toDecodedList work correctly', () {
        final listValue = [10, 20, 30];
        final encoded = IsolateType.wrap(listValue) as IsolateList;

        // Use toList to get the wrapped items.
        final wrappedList = encoded.toList<IsolateType>();
        expect(wrappedList, isA<List<IsolateType>>());
        expect(wrappedList.length, equals(listValue.length));

        // Using toDecodedList to return the original values.
        final decodedList = encoded.toDecodedList<num>();
        expect(decodedList, equals(listValue));
      });
    });

    group('IsolateMap helper methods', () {
      test('toMap and toDecodedMap work correctly', () {
        final mapValue = {
          'x': 100,
          'y': 200,
        };
        final encoded = IsolateType.wrap(mapValue) as IsolateMap;

        // Testing toMap which casts the internal map to specified types.
        final wrappedMap = encoded.toMap<IsolateString, IsolateType>();
        expect(wrappedMap, isA<Map<IsolateString, IsolateType>>());
        expect(wrappedMap.length, equals(mapValue.length));

        // Using toDecodedMap to get original Map.
        final decodedMap = encoded.toDecodedMap<String, int>();
        expect(decodedMap, equals(mapValue));
      });
    });

    test('Isolate types conversion and equality', () {
      // Test number conversions
      expect(const IsolateNum(10) == const IsolateNum(10), isTrue);
      expect(const IsolateNum(10) == const IsolateNum(11), isFalse);

      // Test string equality
      expect(
        const IsolateString('test') == const IsolateString('test'),
        isTrue,
      );
      expect(
        const IsolateString('test') == const IsolateString('other'),
        isFalse,
      );

      // Test bool equality
      expect(const IsolateBool(true) == const IsolateBool(true), isTrue);
      expect(const IsolateBool(true) == const IsolateBool(false), isFalse);
    });
  });

  group('IsolateManager additional tests', () {
    test('Test restart() when isolate is not started', () async {
      final isolateManager = IsolateManager<int, int>.create(
        fibonacci,
        concurrent: 2,
      );

      // Restart without starting first
      await isolateManager.restart();
      expect(isolateManager.isStarted, equals(true));

      final result = await isolateManager.compute(5);
      expect(result, equals(fibonacci(5)));

      await isolateManager.stop();
    });

    test('Test multiple starts have no effect', () async {
      final isolateManager = IsolateManager<int, int>.create(
        fibonacci,
      );

      await isolateManager.start();
      final firstStart = isolateManager.isStarted;

      // Second start should have no effect
      await isolateManager.start();
      expect(isolateManager.isStarted, equals(firstStart));

      await isolateManager.stop();
    });

    test('Test stop() when isolate is not started', () async {
      final isolateManager = IsolateManager<int, int>.create(
        fibonacci,
      );

      // Stop without starting
      await isolateManager.stop();
      expect(isolateManager.isStarted, equals(false));
    });

    test('Test compute() with priority parameter', () async {
      final isolateManager = IsolateManager<int, int>.create(
        fibonacci,
      );

      // Add several tasks
      final futures = <Future<int>>[];
      for (var i = 0; i < 5; i++) {
        futures.add(isolateManager.compute(i));
      }

      // Add a high priority task
      final priorityResult = await isolateManager.compute(10, priority: true);
      expect(priorityResult, equals(fibonacci(10)));

      // Complete other tasks
      await Future.wait(futures);

      await isolateManager.stop();
    });

    test('Test stream broadcasts to multiple listeners', () async {
      final isolateManager = IsolateManager<int, int>.create(
        fibonacci,
      );

      final receivedValues1 = <int>[];
      final receivedValues2 = <int>[];

      // Add multiple listeners to stream
      final subscription1 = isolateManager.stream.listen(receivedValues1.add);

      final subscription2 = isolateManager.stream.listen(receivedValues2.add);

      // Compute a value
      await isolateManager.compute(5);

      // Give some time for streams to process
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(receivedValues1, contains(5));
      expect(receivedValues2, contains(5));

      await subscription1.cancel();
      await subscription2.cancel();
      await isolateManager.stop();
    });

    test('Test ensureStarted future completes after start', () async {
      final isolateManager = IsolateManager<int, int>.create(
        fibonacci,
      );

      // Start in background
      isolateManager.start().ignore();

      // Wait for start to complete
      await isolateManager.ensureStarted;
      expect(isolateManager.isStarted, equals(true));

      await isolateManager.stop();
    });

    test('Test run static method with debug enabled', () async {
      final result = await IsolateManager.run(
        () => fibonacci(5),
        isDebug: true,
      );

      expect(result, equals(fibonacci(5)));
    });

    test('Test runFunction static method with named worker', () async {
      final result = await IsolateManager.runFunction(
        fibonacci,
        5,
        workerName: 'fibonacci',
        isDebug: true,
      );

      expect(result, equals(fibonacci(5)));
    });

    test('Test runCustomFunction static method with callback', () async {
      var progressCount = 0;

      final result = await IsolateManager.runCustomFunction(
        isolateCallbackSimpleFunction,
        5,
        workerName: 'isolateCallbackSimpleFunction',
        callback: (value) {
          // Count progress updates
          progressCount++;
          return progressCount >
              8; // Return true after receiving 9 progress updates
        },
        isDebug: true,
      );

      expect(progressCount, greaterThanOrEqualTo(9));
      expect(result, isNotNull);
    });

    test('Test IsolateManager with custom debug prefix', () async {
      final originalPrefix = IsolateManager.debugLogPrefix;
      IsolateManager.debugLogPrefix = 'Custom Debug';

      final isolateManager = IsolateManager<int, int>.create(
        fibonacci,
        isDebug: true,
      );

      await isolateManager.start();
      final result = await isolateManager.compute(5);
      expect(result, equals(fibonacci(5)));

      await isolateManager.stop();

      // Restore original prefix
      IsolateManager.debugLogPrefix = originalPrefix;
    });

    test('Test IsolateManager with converter function', () async {
      final isolateManager = IsolateManager.create(
        fibonacci,
        converter: (value) => 'Result: $value',
        workerConverter: (value) => 'Result: $value',
      );

      await isolateManager.start();
      final result = await isolateManager.compute(5);
      expect(result, equals('Result: ${fibonacci(5)}'));

      await isolateManager.stop();
    });

    test('Test IsolateManager.run with worker parameter', () async {
      final result = await IsolateManager.run(
        () => fibonacciRecursive(5),
        workerName: 'fibonacciRecursive',
        workerParameter: 5,
      );

      expect(result, equals(fibonacciRecursive(5)));
    });

    test('Test QueueStrategy clear method', () async {
      final strategy = QueueStrategyRemoveNewest<int, int>(maxCount: 10);

      for (var i = 0; i < 5; i++) {
        strategy.add(IsolateQueue<int, int>(i, null));
      }

      expect(strategy.queuesCount, equals(5));
      strategy.clear();
      expect(strategy.queuesCount, equals(0));
      expect(strategy.hasNext(), equals(false));
    });

    test('Test IsolateManager pause and restart behavior', () async {
      final isolateManager = IsolateManager<int, int>.create(
        fibonacci,
        concurrent: 2,
        isDebug: true,
      );

      await isolateManager.start();
      expect(isolateManager.isStarted, equals(true));

      final resultBefore = await isolateManager.compute(10);
      expect(resultBefore, equals(fibonacci(10)));

      await isolateManager.pause();
      expect(isolateManager.isStarted, equals(false));

      await isolateManager.restart();
      expect(isolateManager.isStarted, equals(true));

      final resultAfter = await isolateManager.compute(10);
      expect(resultAfter, equals(fibonacci(10)));

      await isolateManager.stop();
    });

    test('Stop after stop should not throw', () async {
      final isolates = IsolateManager.createShared();
      await isolates.stop();

      // Should not throw
      await isolates.stop();

      // Verify isolate is still stopped
      expect(isolates.isStarted, isFalse);

      // Additional check - computation should not work
      try {
        await isolates.compute(add, <int>[1, 2]);
        fail('Should not reach here - compute should fail on stopped isolate');
      } catch (e) {
        // Expected exception
      }
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
    test('QueueStrategyUnlimited with multiple operations', () {
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
      expect(result, isEmpty);
    });

    test('QueueStrategyUnlimited edge case: empty queue', () {
      final queueStrategies = QueueStrategyUnlimited<int, int>();
      expect(queueStrategies.queuesCount, equals(0));
      expect(queueStrategies.hasNext(), isFalse);
      expect(queueStrategies.getNext, throwsA(isA<AssertionError>()));
    });

    test('QueueStrategyUnlimited alternating add and remove', () {
      final queueStrategies = QueueStrategyUnlimited<int, int>()
        ..add(IsolateQueue<int, int>(1, null));
      expect(queueStrategies.queuesCount, equals(1));
      expect(queueStrategies.getNext().params, equals(1));

      queueStrategies
        ..add(IsolateQueue<int, int>(2, null))
        ..add(IsolateQueue<int, int>(3, null));
      expect(queueStrategies.queuesCount, equals(2));
      expect(queueStrategies.getNext().params, equals(2));

      queueStrategies.add(IsolateQueue<int, int>(4, null));
      expect(queueStrategies.queuesCount, equals(2));
      expect(queueStrategies.getNext().params, equals(3));
      expect(queueStrategies.getNext().params, equals(4));
      expect(queueStrategies.hasNext(), isFalse);
    });

    test('QueueStrategyRemoveNewest with default behavior', () {
      final queueStrategies = QueueStrategyRemoveNewest<int, int>(maxCount: 3);
      for (var i = 0; i < 10; i++) {
        queueStrategies.add(IsolateQueue<int, int>(i, null));
      }
      expect(queueStrategies.queuesCount, equals(3));
      final result = <int>[0, 1, 9];
      while (queueStrategies.hasNext()) {
        expect(queueStrategies.getNext().params, equals(result.removeAt(0)));
      }
      expect(result, isEmpty);
    });

    test('QueueStrategyRemoveNewest with addToTop true', () {
      final queueStrategies = QueueStrategyRemoveNewest<int, int>(maxCount: 3);
      for (var i = 0; i < 10; i++) {
        queueStrategies.add(IsolateQueue<int, int>(i, null), addToTop: true);
      }
      expect(queueStrategies.queuesCount, equals(3));
      final result = <int>[9, 8, 7];
      while (queueStrategies.hasNext()) {
        expect(queueStrategies.getNext().params, equals(result.removeAt(0)));
      }
      expect(result, isEmpty);
    });

    test('QueueStrategyRemoveNewest edge case: single element', () {
      final queueStrategies = QueueStrategyRemoveNewest<int, int>(maxCount: 3)
        ..add(IsolateQueue<int, int>(100, null));
      expect(queueStrategies.queuesCount, equals(1));
      expect(queueStrategies.getNext().params, equals(100));
      expect(queueStrategies.hasNext(), isFalse);
    });

    test('QueueStrategyRemoveOldest with default behavior', () {
      final queueStrategies = QueueStrategyRemoveOldest<int, int>(maxCount: 3);
      for (var i = 0; i < 10; i++) {
        queueStrategies.add(IsolateQueue<int, int>(i, null));
      }
      expect(queueStrategies.queuesCount, equals(3));
      final result = <int>[7, 8, 9];
      while (queueStrategies.hasNext()) {
        expect(queueStrategies.getNext().params, equals(result.removeAt(0)));
      }
      expect(result, isEmpty);
    });

    test('QueueStrategyRemoveOldest with addToTop true', () {
      final queueStrategies = QueueStrategyRemoveOldest<int, int>(maxCount: 3);
      for (var i = 0; i < 10; i++) {
        queueStrategies.add(IsolateQueue<int, int>(i, null), addToTop: true);
      }
      expect(queueStrategies.queuesCount, equals(3));
      // With addToTop, the newest goes to front, but removal still drops oldest elements.
      // The resulting order depends on internal handling.
      final result = <int>[9, 1, 0];
      while (queueStrategies.hasNext()) {
        expect(queueStrategies.getNext().params, equals(result.removeAt(0)));
      }
      expect(result, isEmpty);
    });

    test('QueueStrategyDiscardIncoming with default behavior', () {
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
      expect(result, isEmpty);
    });

    test('QueueStrategyDiscardIncoming with addToTop true', () {
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
      expect(result, isEmpty);
    });

    test('QueueStrategyDiscardIncoming edge case: adding when full', () {
      final queueStrategies =
          QueueStrategyDiscardIncoming<int, int>(maxCount: 2)
            ..add(IsolateQueue<int, int>(1, null))
            ..add(IsolateQueue<int, int>(2, null))
            // Should discard incoming value since max count is reached.
            ..add(IsolateQueue<int, int>(3, null));
      expect(queueStrategies.queuesCount, equals(2));
      final result = <int>[1, 2];
      while (queueStrategies.hasNext()) {
        expect(queueStrategies.getNext().params, equals(result.removeAt(0)));
      }
      expect(result, isEmpty);
    });
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
  return IsolateNum(number.unwrap);
}

@isolateManagerWorker
IsolateString isolateTypeString(IsolateString string) {
  return IsolateString(string.unwrap);
}

@isolateManagerWorker
IsolateBool isolateTypeBool(IsolateBool boolean) {
  return IsolateBool(boolean.unwrap);
}

@isolateManagerWorker
IsolateList isolateTypeList(IsolateList numbers) {
  return IsolateList(numbers.unwrap.map((e) => IsolateString('$e')).toList());
}

@isolateManagerWorker
IsolateMap isolateTypeMap(IsolateList numbers) {
  return IsolateMap(
    Map.fromEntries(
      numbers.unwrap.map(
        (e) => MapEntry(IsolateString('$e'), IsolateNum(e as num)),
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
