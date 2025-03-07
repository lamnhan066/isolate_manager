# Isolate Manager

[![codecov](https://codecov.io/gh/lamnhan066/isolate_manager/graph/badge.svg?token=MSREWDRA4E)](https://codecov.io/gh/lamnhan066/isolate_manager)
[![Pub Version](https://img.shields.io/pub/v/isolate_manager)](https://pub.dev/packages/isolate_manager)
[![Pub Points](https://img.shields.io/pub/points/isolate_manager)](https://pub.dev/packages/isolate_manager)
[![Pub Downloads](https://img.shields.io/pub/dm/isolate_manager)](https://pub.dev/packages/isolate_manager)
[![Pub Likes](https://img.shields.io/pub/likes/isolate_manager)](https://pub.dev/packages/isolate_manager)

[![PubStats Popularity](https://pubstats.dev/badges/packages/isolate_manager/popularity.svg)](https://pubstats.dev/packages/isolate_manager)
[![PubStats Rank](https://pubstats.dev/badges/packages/isolate_manager/rank.svg)](https://pubstats.dev/packages/isolate_manager)
[![PubStats Dependents](https://pubstats.dev/badges/packages/isolate_manager/dependents.svg)](https://pubstats.dev/packages/isolate_manager)

## What is Isolate Manager?

A powerful Flutter/Dart package that simplifies concurrent programming using isolates, with cross-platform support including web and WebAssembly.

## Features

- **Flexible Isolate Management:**
  - **One-off Isolates:** For single computations (similar to `Isolate.run`) with web worker support
  - **Long-lived Single Function Isolates:** One instance per function with stream capabilities
  - **Long-lived Multi-Function Isolates:** One instance to handle multiple functions (ideal for shared operations)
  
- **Cross-Platform Support:** 
  - **Web & WASM Compatible:** Automatically compiles functions to JavaScript Workers on web
  - Falls back to `Future`/`Stream` if Workers aren't available
  - Full support for VMs, Web JS and WASM

- **Smart Queue Management:**
  - Automatically queues multiple computations
  - Supports priority tasks
  - Customizable queue strategies with different behaviors when queue limits are reached

- **Type Safety & Error Handling:**
  - Specialized types (`ImNum`, `ImString`, `ImBool`, `ImList` and `ImMap`) ensure only transferable data is exchanged
  - Robust exception handling across VMs, Web JS, and WASM by extending `IsolateException`

## Setup

Functions used in isolates **must** be `static` or top-level. Add `@pragma('vm:entry-point')` to prevent tree-shaking:

```dart
@pragma('vm:entry-point')
int add(List<int> values) {
  return values[0] + values[1];
}
```

## Annotations & Platform Setup

- **Function Annotations:**
  - `@isolateManagerWorker` – For one-off or single-function isolates
  - `@isolateManagerSharedWorker` – For shared multi-function isolates
  - `@isolateManagerCustomWorker` – For custom isolate functions with manual control

- **Platform-Specific Setup:**
  - **Mobile/Desktop:** No additional setup required
  - **Web:** Functions must not depend on Flutter libraries. Only Dart primitives, Maps, and Lists are allowed. Generate the JavaScript Workers with:
    ```shell
    dart run isolate_manager:generate
    ```

  - **WASM Notes:**
    - When using WebAssembly, `int` types (including in collections) are processed as `double`. A built-in converter automatically fixes this, or disable with `enableWasmConverter: false`
    - If the app hangs when running with `flutter run -d chrome --wasm`, use:
      ```shell
      flutter run -d chrome --wasm --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp
      ```

## Usage Examples

### One-off Isolate

Use a one-off isolate with either of these methods:

```dart
@isolateManagerWorker
int fibonacciRecursive(int n) {
  if (n == 0) return 0;
  if (n == 1) return 1;
  return fibonacciRecursive(n - 1) + fibonacciRecursive(n - 2);
}

// Option 1: Explicit worker parameters
final fibo40 = await IsolateManager.run(
  () => fibonacciRecursive(40),
  workerName: 'fibonacciRecursive',
  workerParameter: 40,
);

// Option 2: Automatic worker mapping
final fibo40 = await IsolateManager.runFunction(fibonacciRecursive, 40);
```

### Long-lived Multi-Function Isolates

```dart
void main() async {
  final isolateShared = IsolateManager.createShared(
    concurrent: 3,
    useWorker: true,
    workerMappings: {
      addFuture: 'addFuture',
      add: 'add',
    },
  );

  final added1 = await isolateShared.compute(addFuture, [1.1, 2.2]);
  print('addFuture: 1.1 + 2.2 = $added1');

  final added2 = await isolateShared.compute(add, [1, 2]);
  print('add: 1 + 2 = $added2');
}

@isolateManagerSharedWorker
Future<double> addFuture(List<double> values) async {
  return values[0] + values[1];
}

@isolateManagerSharedWorker
int add(List<int> values) {
  return values[0] + values[1];
}
```

### Long-lived Single Function Isolate

```dart
main() async {
  final isolate = IsolateManager.create(
    fibonacci,
    workerName: 'fibonacci',
    concurrent: 2,
  );

  isolate.stream.listen((value) {
    print('Intermediate value: $value');
  });

  final fibo = await isolate(20);
  await isolate.stop(); // Or `restart` if you want to restart
}

@isolateManagerWorker
int fibonacci(int n) {
  if (n == 0) return 0;
  if (n == 1) return 1;
  return fibonacci(n - 1) + fibonacci(n - 2);
}
```

### Custom Function Usage & Try-Catch

Define a custom function with full control over events, error handling, and progress updates:

```dart
main() {
  final isolateManager = IsolateManager.createCustom(
    customIsolateFunction,
    workerName: 'customIsolateFunction',
    debugMode: true,
  );

  try {
    final fibo40 = await isolateManager.compute(40);
  } catch (e) {
    // Exception handling
  }
}

@isolateManagerCustomWorker
void customIsolateFunction(dynamic params) {
  IsolateManagerFunction.customFunction<int, int>(
    params,
    onEvent: (controller, message) {
      try {
        final result = fibonacci(message);
        controller.sendResult(result);
      } catch (err, stack) {
        controller.sendResultError(IsolateException(err, stack));
      }
      return 0;
    },
    onInit: (controller) {
      // Initialization logic here
    },
    onDispose: (controller) {
      // Cleanup actions here
    },
    autoHandleException: false,
    autoHandleResult: false,
  );
}
```

## Advanced Features

### Queue Management

- **Priority Tasks:** Set `priority: true` to move critical computations to the front of the queue
- **Queue Limits:** Define `maxCount` to limit queued tasks
- **Queue Strategies:** Customize behavior when the limit is reached:
  - `QueueStrategyUnlimited()` – No limit (default)
  - `QueueStrategyRemoveNewest()` – Removes the newest task when full
  - `QueueStrategyRemoveOldest()` – Removes the oldest task when full
  - `QueueStrategyDiscardIncoming()` – Discards new tasks when full
- **Custom Queue Strategy:** Extend `QueueStrategy` to implement your own logic:

  ```dart
  class CustomQueueStrategy<R, P> extends QueueStrategy<R, P> {
    @override
    bool continueIfMaxCountExceeded() {
      // Custom logic using `queues`, `queuesCount`, and `maxCount`
      return true; // Allow new tasks by default
    }
  }
  ```

### Progress Updates

Receive progress updates before the final result:

```dart
main() {
  final isolateManager = IsolateManager.createCustom(progressFunction);

  final result = await isolateManager.compute(100, callback: (value) {
    final data = jsonDecode(value);
    if (data.containsKey('progress')) {
      print('Progress: ${data['progress']}');
      return false; // Indicates this is a progress update
    }
    print('Final result: ${data['result']}');
    return true; // Final result received
  });
}

@isolateManagerCustomWorker
void progressFunction(dynamic params) {
  IsolateManagerFunction.customFunction<String, int>(
    params,
    onEvent: (controller, message) {
      // Send progress updates
      for (int i = 0; i < message; i++) {
        final progress = jsonEncode({'progress': i});
        controller.sendResult(progress);
      }

      // Send final result
      return jsonEncode({'result': message});
    },
  );
}
```

### Type Safety for Web Workers

Use helper types to ensure safe data transfer:

```dart
main() {
  // Convert native Dart objects to ImType:
  try {
    final isolate = IsolateManager.create(isolateFunction, workerName: 'isolateFunction');
    final param = ImList.wrap({'k1': 'v1', 'k2': 'v2'});

    final result = await isolate.compute(param);
  } on UnsupportedImTypeException catch (e) {
    // Throws `UnsupportedImTypeException` when there is unsupported type
  }
}

@isolateManagerWorker
ImMap isolateFunction(ImList numbers) {
  // Decode the list into standard Dart types
  final data = numbers.unwrap!;
  final map = Map.fromEntries(
    data.map((e) => MapEntry(ImString('$e'), ImNum(e as num))),
  );
  return ImMap(map);
}

```

Available `ImType`s:

```dart
final number = ImNum(1); // or 1.0
final string = ImString('text');
final boolean = ImBool(true);
final list = ImList(<ImType>[]);
final map = ImMap(<ImType, ImType>{});
```

### Exception Safety for Web Workers

Create exceptions that can be safely transferred between isolates:

```dart
main() {
  IsolateManager.registerException(
    (message, stackTrace) => CustomIsolateException(message),
  );

  final isolate = IsolateManager.create(throwsCustomIsolateException);

  try {
    await isolate.compute(ImNum(0));
  } on CustomIsolateException catch (e, s) {
    print(e); // 'Custom Isolate Exception'
  } 
}

class CustomIsolateException extends IsolateException {
  const CustomIsolateException(super.error);

  @override
  String get name => 'CustomIsolateException';
}

@isolateManagerWorker
ImNum throwsCustomIsolateException(ImNum number) {
  throw const CustomIsolateException('Custom Isolate Exception');
}
```

## Generator Commands & Flags

Generate JavaScript Workers after adding or modifying annotated functions:

```shell
dart run isolate_manager:generate
```

Additional options:

- `--single` – Generate only single-function isolates
- `--shared` – Generate only shared-function isolates
- `--in <path>` (or `-i <path>`) – Input folder
- `--out <path>` (or `-o <path>`) – Output folder
- `--obfuscate <level>` – JS obfuscation level (0–4, default is 4)
- `--debug` – Retain temporary files for debugging
- `--worker-mappings-experiment=lib/main.dart` – Auto-generate worker mappings (experiment)

## Additional Information

- **Queue Info:** Use `queuesLength` to get the current queue size
- **Startup Control:** Use `ensureStarted` to await manual start; check `isStarted` to see if initialization is complete
- **Static Methods:** For static functions, specify the worker name as `"ClassName.functionName"`
- **Data Flow:** When using converters, data flows from Main → Worker → Main → Converter → Final Result

## Benchmark

Recursive Fibonacci benchmarks (measured in microseconds on a MacBook M1 Pro 14" with 16GB RAM):

- **VM**

| Fibonacci | Main App  | One Isolate | Three Isolates | IsolateManager.runFunction | IsolateManager.run | Isolate.run |
|:---------:|----------:|------------:|---------------:|---------------------------:|-------------------:|------------:|
| 30        | 542,788   | 546,776     | 195,634        | 581,030                    | 556,381            | 539,848     |
| 33        | 2,275,882 | 2,270,587   | 826,524        | 2,303,890                  | 2,297,313          | 2,285,464   |
| 36        | 9,798,373 | 9,660,129   | 3,451,513      | 9,707,627                  | 9,641,757          | 9,643,465   |

- **Chrome (with Worker support)**

| Fibonacci | Main App   | One Isolate | Three Isolates | IsolateManager.runFunction | IsolateManager.run | Isolate.run (Unsupported) |
|:---------:|-----------:|------------:|---------------:|---------------------------:|-------------------:|---------------------------:|
| 30        | 2,121,599  | 553,000     | 200,100        | 1,110,200                  | 1,085,899          | 0                         |
| 33        | 9,022,701  | 2,303,101   | 820,800        | 2,834,500                  | 2,836,200          | 0                         |
| 36        | 38,152,701 | 9,749,801   | 3,443,399      | 10,229,201                 | 10,254,599         | 0                         |

[Detailed benchmark info](https://github.com/lamnhan066/isolate_manager/tree/v6.0.0/benchmark)

## Contributions

If you encounter issues or have suggestions for improvements, please open an issue or submit a pull request. If you appreciate this work, consider buying me a coffee:

[![BMC QR](https://raw.githubusercontent.com/lamnhan066/isolate_manager/main/assets/images/bmc_qr.png)](https://www.buymeacoffee.com/lamnhan066)