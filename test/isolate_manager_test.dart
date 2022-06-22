import 'package:isolate_contactor/isolate_contactor.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:test/test.dart';

void main() {
  test('Test IsolateManager', () async {
    // Create IsolateContactor
    IsolateManager<int> isolateManager =
        IsolateManager.create(numOfIsolates: 4, isolateFunction: fibonacci);

    await isolateManager.start();

    await Future.wait([
      for (int i = 0; i < 10; i++)
        isolateManager.compute(i).then((value) {
          print('Fibonacci $i = $value');
          expect(value, fibonacci(i));
        })
    ]);

    // for (int i = 0; i < 2; i++) {
    //   await isolateManager.compute(i).then((value) => print(value));
    // }

    await Future.delayed(Duration(seconds: 3));

    // Dispose
    isolateManager.stop();
  });

  test('Test IsolateManager', () async {
    // Create IsolateContactor
    IsolateManager<int> isolateManager = IsolateManager.createOwnIsolate(
      numOfIsolates: 4,
      isolateFunction: isolateFunction,
    );

    await isolateManager.start();

    await Future.wait([
      for (int i = 0; i < 10; i++)
        isolateManager.compute(i).then((value) {
          print('Fibonacci $i = $value');
          expect(value, fibonacci(i));
        })
    ]);

    // for (int i = 0; i < 2; i++) {
    //   await isolateManager.compute(i).then((value) => print(value));
    // }

    await Future.delayed(Duration(seconds: 3));

    // Dispose
    isolateManager.stop();
  });
}

int fibonacci(dynamic n) {
  if (n <= 2) return 1;

  int n1 = 0, n2 = 1, n3 = 1;

  for (int i = 2; i <= n; i++) {
    n3 = n1 + n2;
    n1 = n2;
    n2 = n3;
  }

  return n3.round();
}

void isolateFunction(dynamic params) {
  final controller = IsolateContactorController(params);

  controller.onIsolateMessage.listen((message) {
    final result = fibonacci(message);

    controller.sendResult(result);
  });
}
