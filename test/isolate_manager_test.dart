import 'dart:convert';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:test/test.dart';

//  dart test
//  dart test --platform=chrome,vm

void main() {
  test('Test IsolateManager.create: Basic Usage', () async {
    // Create IsolateContactor
    print('Create IsolateManager instance');
    final isolateManager = IsolateManager.create(
      fibonacci,
      concurrent: 4,
    );

    print('Computing IsolateManager instance...');
    final result = await isolateManager.compute(3);

    expect(result, fibonacci(3));

    print('Dispose IsolateManager instance.');
    isolateManager.stop();
  });

  test('Test IsolateManager.create', () async {
    // Create IsolateContactor
    print('Create IsolateManager instance');
    final isolateManager = IsolateManager.create(
      fibonacci,
      concurrent: 4,
    );

    print('Starting IsolateManager instance...');
    isolateManager.start();

    print('Computing IsolateManager instance...');
    await Future.wait([
      for (int i = 0; i < 10; i++)
        isolateManager.compute(i).then((value) {
          print('Fibonacci $i = $value');
          expect(value, fibonacci(i));
        })
    ]);

    await Future.delayed(Duration(seconds: 3));

    print('Dispose IsolateManager instance.');
    isolateManager.stop();
  });

  test('Test IsolateManager.createOwnIsolate', () async {
    // Create IsolateContactor
    print('Create IsolateManager instance');
    final isolateManager = IsolateManager<int, int>.createOwnIsolate(
      isolateFunction,
      concurrent: 4,
      initialParams: ['Test initialParams 0', 'Test initialParams 1'],
    )..start();

    isolateManager.stream.listen((value) {
      print('Stream: $value');
    });

    print('Computing IsolateManager instance...');
    await Future.wait([
      for (int i = 0; i < 10; i++)
        isolateManager.compute(i).then((value) {
          print('Fibonacci $i = $value');
          expect(value, fibonacci(i));
        })
    ]);
    await Future.delayed(Duration(seconds: 3));

    print('Restarting IsolateManager instance...');
    await isolateManager.restart();

    print('Computing IsolateManager instance second times...');
    await Future.wait([
      for (int i = 5; i < 13; i++)
        isolateManager.compute(i).then((value) {
          print('Fibonacci $i = $value');
          expect(value, fibonacci(i));
        })
    ]);

    await Future.delayed(Duration(seconds: 3));

    print('Dispose IsolateManager instance.');
    await isolateManager.stop();
  });

  test('Test IsolateManager.create with Worker', () async {
    // Create IsolateContactor
    print('Create IsolateManager instance');
    final isolateManager = IsolateManager.create(
      fibonacci,
      workerName: 'fibonacci',
      concurrent: 4,
    );

    print('Starting IsolateManager instance...');
    await isolateManager.start();

    print('Computing IsolateManager instance...');
    await Future.wait([
      for (int i = 0; i < 10; i++)
        isolateManager.compute(i).then((value) {
          final realFib = fibonacci(i);
          print('Fibonacci $i = $value == $realFib');

          expect(value, realFib);
        })
    ]);

    await Future.delayed(Duration(seconds: 3));

    print('Dispose IsolateManager instance.');
    isolateManager.stop();
  });

  test('Test with Exception function', () async {
    final isolateManager = IsolateManager.create(
      errorFunction,
      concurrent: 1,
      isDebug: true,
    );
    await isolateManager.start();

    expect(
      () async => await isolateManager.compute([50, 50]),
      throwsStateError,
    );

    await Future.delayed(Duration(seconds: 3));

    await isolateManager.stop();
  });

  test('Test with Exception function with eagerError is true', () async {
    final isolateManager = IsolateManager.create(
      errorFunction,
      concurrent: 2,
      isDebug: true,
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

  test('Test with Exception function with eagerError is false', () async {
    final isolateManager = IsolateManager.create(
      errorFunction,
      concurrent: 2,
      isDebug: true,
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

  test('Test with IsolateCallback', () async {
    final isolateManager = IsolateManager<String, int>.createOwnIsolate(
      isolateCallbackFunction,
      concurrent: 1,
      isDebug: true,
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
  final controller = IsolateManagerController<int, int>(params);

  final initialParams = controller.initialParams;
  print('initialParams 0: ${initialParams[0]}');
  print('initialParams 1: ${initialParams[1]}');

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
    throw StateError('The exception is threw at value[0] = ${value[0]}');
  }
  return value[0] + value[1];
}
