import 'dart:async';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:test/test.dart';

import '../test/isolate_manager_test.dart';
import 'models/user.dart';

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

  group('Isolate Types -', () {
    final isolates = IsolateManager.createShared(useWorker: true);

    setUpAll(() async {
      await isolates.start();
    });

    tearDownAll(() async {
      await isolates.stop();
    });

    test('Unimplemented Type', () {
      final user = User(name: 'user', email: 'user@user.com');
      expect(() => IsolateType.encode(user), throwsUnimplementedError);
    });

    test('num', () async {
      final value = IsolateNum(15);

      final result = await isolates.compute(isolateTypeNum, value);

      expect(result, isA<IsolateNum>());
      expect(result, equals(value));
    });

    test('num toDouble', () {
      const doubleValue = 15.0;
      final value = IsolateNum(doubleValue).toDouble();

      expect(value, isA<double>());
      expect(value, equals(doubleValue));
    });

    test('num toInt', () {
      const doubleValue = 15;
      final value = IsolateNum(doubleValue).toInt();

      expect(value, isA<int>());
      expect(value, equals(doubleValue));
    });

    test('encode, decode IsolateList', () {
      final list = <Object>['1', 1, 1.0, false];
      final value = IsolateType.encode(list);

      expect(value, isA<IsolateList>());
      expect(value.decode, equals(list));
    });

    test('encode, decode IsolateMap', () {
      final map = <String, Object>{'k1': '1', 'k2': 1, 'k3': 1.0, 'k4': false};
      final value = IsolateType.encode(map);

      expect(value, isA<IsolateMap>());
      expect(value.decode, equals(map));
    });

    test('String', () async {
      final value = IsolateString('abc');

      final result = await isolates.compute(isolateTypeString, value);

      expect(result, isA<IsolateString>());
      expect(result, equals(value));
    });

    test('bool', () async {
      final value = IsolateBool(false);

      final result = await isolates.compute(isolateTypeBool, value);

      expect(result, isA<IsolateBool>());
      expect(result, equals(value));
    });

    test('List', () async {
      final value = IsolateList(<IsolateNum>[IsolateNum(100)]);

      final result = await isolates.compute(isolateTypeList, value);

      expect(result, isA<IsolateList>());
      expect(
        result,
        equals(IsolateList(<IsolateString>[IsolateString('100')])),
      );
    });

    test('Map', () async {
      final result = await isolates.compute(
        isolateTypeMap,
        IsolateList([IsolateNum(5), IsolateNum(7)]),
      );

      expect(result, isA<IsolateMap>());
      expect(
        result,
        equals(
          IsolateMap({
            IsolateString('5'): IsolateNum(5),
            IsolateString('7'): IsolateNum(7),
          }),
        ),
      );
    });
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
IsolateNum isolateTypeNum(IsolateNum number) {
  return IsolateNum(number.decode);
}

@isolateManagerSharedWorker
IsolateString isolateTypeString(IsolateString string) {
  return IsolateString(string.decode);
}

@isolateManagerSharedWorker
IsolateBool isolateTypeBool(IsolateBool boolean) {
  return IsolateBool(boolean.decode);
}

@isolateManagerSharedWorker
IsolateList isolateTypeList(IsolateList numbers) {
  return IsolateList(numbers.decode?.map((e) => IsolateString('$e')).toList());
}

@isolateManagerSharedWorker
IsolateMap isolateTypeMap(IsolateList numbers) {
  return IsolateMap(
    Map.fromEntries(
      numbers.decode!
          .map((e) => MapEntry(IsolateString('$e'), IsolateNum(e! as num))),
    ),
  );
}

void _addWorkerMappings() {
  IsolateManager.addWorkerMapping(isolateTypeMap, 'isolateTypeMap');
  IsolateManager.addWorkerMapping(isolateTypeList, 'isolateTypeList');
  IsolateManager.addWorkerMapping(isolateTypeBool, 'isolateTypeBool');
  IsolateManager.addWorkerMapping(isolateTypeString, 'isolateTypeString');
  IsolateManager.addWorkerMapping(isolateTypeNum, 'isolateTypeNum');
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
