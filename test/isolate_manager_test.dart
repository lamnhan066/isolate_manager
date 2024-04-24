import 'dart:async';
import 'dart:convert';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager/src/isolate_worker/isolate_worker_stub.dart'
    as isolate_worker_stub;
import 'package:test/test.dart';

//  dart test
//  dart test --platform=chrome,vm

void main() {
  group('Test funtions -', () {
    test('isolateWorker stub', () {
      expect(
        () => isolate_worker_stub.isolateWorker((message) {}),
        throwsUnimplementedError,
      );
    });
  });

  test('Test IsolateManager.create: Basic Usage', () async {
    // Create IsolateContactor
    final isolateManager = IsolateManager.create(
      fibonacci,
      concurrent: 4,
    );

    final result = await isolateManager.compute(3);

    expect(result, fibonacci(3));

    isolateManager.stop();
  });

  test('Test IsolateManager.create', () async {
    // Create IsolateContactor
    final isolateManager = IsolateManager.create(
      fibonacci,
      concurrent: 4,
    );

    expect(isolateManager.isStarted, equals(false));

    await isolateManager.start();

    expect(isolateManager.isStarted, equals(true));
    await isolateManager.ensureStarted;

    expect(isolateManager.queuesLength, equals(0));

    await Future.wait([
      for (int i = 0; i < 10; i++)
        isolateManager.compute(i).then((value) {
          expect(value, fibonacci(i));
        })
    ]);

    await Future.delayed(Duration(seconds: 3));

    isolateManager.stop();
  });

  test('Test IsolateManager.createOwnIsolate', () async {
    // Create IsolateContactor
    final isolateManager = IsolateManager<int, int>.createOwnIsolate(
      isolateFunction,
      concurrent: 4,
      initialParams: ['Test initialParams 0', 'Test initialParams 1'],
    )..start();

    isolateManager.stream
        .listen((value) {})
        // Do not need to catch the error here
        .onError((error) {});

    await Future.wait([
      for (int i = 0; i < 10; i++)
        isolateManager.compute(i).then((value) {
          expect(value, fibonacci(i));
        })
    ]);
    await Future.delayed(Duration(seconds: 3));

    await isolateManager.restart();

    await Future.wait([
      for (int i = 5; i < 13; i++)
        isolateManager.compute(i).then((value) {
          expect(value, fibonacci(i));
        })
    ]);

    expect(() => isolateManager.sendMessage(-1), throwsStateError);

    await Future.delayed(Duration(seconds: 3));

    await isolateManager.stop();
  });

  test('Test IsolateManager.create with Worker', () async {
    // Create IsolateContactor
    final isolateManager = IsolateManager.create(
      fibonacci,
      workerName: 'fibonacci',
      concurrent: 4,
    );

    await isolateManager.start();

    await Future.wait([
      for (int i = 0; i < 10; i++)
        isolateManager.compute(i).then((value) {
          final realFib = fibonacci(i);

          expect(value, realFib);
        })
    ]);

    await Future.delayed(Duration(seconds: 3));

    isolateManager.stop();
  });

  test('Test with Exception function', () async {
    final isolateManager = IsolateManager.create(
      errorFunction,
      concurrent: 1,
    );
    await isolateManager.start();

    expect(
      () async => await isolateManager.compute([50, 50]),
      throwsStateError,
    );

    await Future.delayed(Duration(seconds: 3));

    await isolateManager.stop();
  });

  test('Test with Exception function with available callback', () async {
    final isolateManager = IsolateManager.create(
      errorFunction,
      concurrent: 1,
    );
    await isolateManager.start();

    expect(
      () => isolateManager.compute([50, 50], callback: (value) {
        return true;
      }),
      throwsStateError,
    );

    await Future.delayed(Duration(seconds: 3));

    await isolateManager.stop();
  });

  test('Test with Exception function with eagerError is true', () async {
    final isolateManager = IsolateManager.create(
      errorFunction,
      concurrent: 2,
    );
    await isolateManager.start();
    final List<Future> futures = [];

    for (var i = 0; i < 100; i++) {
      futures.add(isolateManager.compute([i, 20]));
    }

    expect(
      () async => await Future.wait(futures, eagerError: true),
      throwsStateError,
    );

    await Future.delayed(Duration(seconds: 3));

    await isolateManager.stop();
  });

  test(
      'Test with Exception function with eagerError is true with available callback',
      () async {
    final isolateManager = IsolateManager.create(
      errorFunction,
      concurrent: 2,
    );
    await isolateManager.start();
    final List<Future> futures = [];

    for (var i = 0; i < 100; i++) {
      futures.add(isolateManager.compute([i, 20], callback: (value) => true));
    }

    expect(
      () async => await Future.wait(futures, eagerError: true),
      throwsStateError,
    );

    await Future.delayed(Duration(seconds: 3));

    await isolateManager.stop();
  });

  test('Test with Exception function with eagerError is false', () async {
    final isolateManager = IsolateManager.create(
      errorFunction,
      concurrent: 2,
    );
    await isolateManager.start();
    final List<Future> futures = [];

    for (var i = 0; i < 100; i++) {
      futures.add(isolateManager.compute([i, 20]));
    }

    expect(
      () async => await Future.wait(futures, eagerError: false),
      throwsStateError,
    );

    await Future.delayed(Duration(seconds: 3));

    await isolateManager.stop();
  });

  test(
      'Test with Exception function with eagerError is false with available callback',
      () async {
    final isolateManager = IsolateManager.create(
      errorFunction,
      concurrent: 2,
    );
    await isolateManager.start();
    final List<Future> futures = [];

    for (var i = 0; i < 100; i++) {
      futures.add(isolateManager.compute([i, 20], callback: (value) => true));
    }

    expect(
      () async => await Future.wait(futures, eagerError: false),
      throwsStateError,
    );

    await Future.delayed(Duration(seconds: 3));

    await isolateManager.stop();
  });

  test('Test with IsolateCallback', () async {
    final isolateManager = IsolateManager<String, int>.createOwnIsolate(
      isolateCallbackFunction,
      concurrent: 1,
    );
    await isolateManager.start();

    final result = await isolateManager.compute(1, callback: (value) {
      final decoded = jsonDecode(value) as Map;
      // Do not return this [value] as the final result
      if (decoded.containsKey('source')) {
        return false;
      }

      // Return this [value] as the final result
      return true;
    });

    final decoded = jsonDecode(result) as Map;
    expect(
      decoded.containsKey('data'),
      equals(true),
    );

    await isolateManager.stop();
  });
}

@pragma('vm:entry-point')
int fibonacci(int n) {
  if (n < 0) throw StateError('n<0');
  if (n == 0) return 0;
  if (n <= 2) return 1;

  double n1 = 0, n2 = 1, n3 = 1;

  for (int i = 2; i <= n; i++) {
    n3 = n1 + n2;
    n1 = n2;
    n2 = n3;
  }

  return n3.round();
}

@pragma('vm:entry-point')
void isolateFunction(dynamic params) {
  late IsolateManagerController controller;
  controller = IsolateManagerController<int, int>(
    params,
    onDispose: () {
      controller.close();
    },
  );

  // Get the `initialParams`.
  controller.initialParams;

  controller.onIsolateMessage.listen((message) {
    try {
      final result = fibonacci(message);
      controller.sendResult(result);
    } catch (err, stack) {
      controller.sendResultError(IsolateException(err, stack));
    }
  });
}

@pragma('vm:entry-point')
void isolateCallbackFunction(dynamic params) {
  final controller = IsolateManagerController<String, int>(params);

  controller.onIsolateMessage.listen((message) {
    try {
      for (int i = 0; i < 10; i++) {
        controller.sendResult(jsonEncode({'source': '$i'}));
      }

      controller.sendResult(jsonEncode({'data': 'data'}));
    } catch (err, stack) {
      controller.sendResultError(IsolateException(err, stack));
    }
  });
}

@pragma('vm:entry-point')
int errorFunction(List<int> value) {
  if (value[0] == 50) {
    return throw StateError('The exception is threw at value[0] = ${value[0]}');
  }
  return value[0] + value[1];
}
