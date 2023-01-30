import 'package:isolate_manager/isolate_manager.dart';
import 'package:test/test.dart';

//  dart test
//  dart test --platform=chrome,vm

void main() {
  test('Test IsolateManager.create: Basic Usage', () async {
    // Create IsolateContactor
    print('Create IsolateManager instance');
    IsolateManager<int> isolateManager = IsolateManager.create(
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
    IsolateManager<int> isolateManager = IsolateManager.create(
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
    IsolateManager<int> isolateManager = IsolateManager.createOwnIsolate(
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
    IsolateManager<int> isolateManager = IsolateManager.create(
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

  test('Test with Exception function with eagerError is true', () async {
    final isolateManager = IsolateManager.create(
      errorFunction,
      concurrent: 2,
      isDebug: true,
    );
    await isolateManager.start();
    final List<Future> futures = [];

    try {
      for (var i = 0; i < 100; i++) {
        futures.add(isolateManager.compute([i, 20]));
      }

      await Future.wait(futures, eagerError: true);
    } on StateError catch (e) {
      expect(e.message, equals('The exception is threw at value[0] = 50'));
    } finally {
      isolateManager.stop();
    }
  });

  test('Test with Exception function with eagerError is false', () async {
    final isolateManager = IsolateManager.create(
      errorFunction,
      concurrent: 2,
      isDebug: true,
    );
    await isolateManager.start();
    final List<Future> futures = [];

    try {
      for (var i = 0; i < 100; i++) {
        futures.add(isolateManager.compute([i, 20]));
      }

      await Future.wait(futures, eagerError: false);
    } on StateError catch (e) {
      expect(e.message, equals('The exception is threw at value[0] = 50'));
    } finally {
      isolateManager.stop();
    }
  });
}

@pragma('vm:entry-point')
int fibonacci(dynamic n) {
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
  final controller = IsolateManagerController(params);

  final initialParams = controller.initialParams;
  print('initialParams 0: ${initialParams[0]}');
  print('initialParams 1: ${initialParams[1]}');

  controller.onIsolateMessage.listen((message) {
    final result = fibonacci(message);

    controller.sendResult(result);
  });
}

@pragma('vm:entry-point')
int errorFunction(dynamic value) {
  if (value[0] == 50) {
    throw StateError('The exception is threw at value[0] = ${value[0]}');
  }
  return value[0] + value[1];
}
