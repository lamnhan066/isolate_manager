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
  - [One-off Isolates:](#one-off-isolate) For single computations (similar to `Isolate.run`) with web worker support
  - [Long-lived Multi-Function Isolates:](#long-lived-multi-function-isolates) One instance to handle multiple functions (ideal for shared operations)
  - [Long-lived Single Function Isolates:](#long-lived-single-function-isolate) One instance per function with stream capabilities
  
- [Cross-Platform Support:](#annotations--platform-setup)
  - [Web & WASM Compatible:](#web) Automatically compiles functions to JavaScript Workers on web
  - Falls back to `Future`/`Stream` if Workers aren't available
  - Full support for VMs, Web JS and WASM

- [Smart Queue Management:](#queue-management)
  - Automatically queues multiple computations
  - Supports priority tasks
  - Customizable queue strategies with different behaviors when queue limits are reached

- [Type Safety:](#type-safety-for-web-workers)
  - Specialized types (`ImNum`, `ImString`, `ImBool`, `ImList` and `ImMap`) ensure only transferable data is exchanged

- [Exception Safety:](#exception-safety-for-web-workers)
  - Exception handling across VMs, Web JS, and WASM by extending and registering `IsolateException`

- **Additional Features:**
  - [Custom Function:](#custom-function-usage--try-catch) Full manual control over isolate execution
  - [Progress Reporting:](#progress-updates) Send progress updates during computation using the custom function
  - [Code Generation:](#generator-commands--flags) Comprehensive worker generation tools and options
  - [Benchmark:](#benchmark) Compare performance between native isolates, IsolateManager, and other concurrency approaches

## Setup

Functions used in isolates **must** be `static` or top-level. Add `@pragma('vm:entry-point')` to prevent tree-shaking:

```dart
@pragma('vm:entry-point')
int add(List<int> values) {
  return values[0] + values[1];
}
```

## Annotations & Platform Setup

### Mobile/Desktop

- No additional setup required

### Web

- **Function Annotations:** Annotate the methods that you want to generate to the JS Worker.
  - `@isolateManagerWorker` – For one-off or single-function isolates
  - `@isolateManagerSharedWorker` – For shared multi-function isolates
  - `@isolateManagerCustomWorker` – For custom isolate functions with manual control

- **Required:** Functions must not depend on Flutter libraries. Only Dart primitives, Maps, and Lists are allowed or using the [`ImType`s](#type-safety-for-web-workers).

- Generate the JavaScript Workers with:

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
  final sharedIsolate = IsolateManager.createShared(
    concurrent: 3,
    useWorker: true,
    workerMappings: {
      addFuture: 'addFuture',
      add: 'add',
    },
  );

  sharedIsolate.stream.listen((value) {
    print('Intermediate value: $value');
  });


  final added1 = await sharedIsolate.compute(addFuture, [1.1, 2.2]);
  print('addFuture: 1.1 + 2.2 = $added1');

  final added2 = await sharedIsolate.compute(add, [1, 2]);
  print('add: 1 + 2 = $added2');

  await sharedIsolate.stop(); // Or `restart` if you want to restart
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
    final param = ImList.wrap([1, 2, 3]);

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

Available `ImType`s (non-nullable types only):

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
  // Register the custom exception type for proper isolate communication
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

Ensure that [the platform setup for the web](#web) is completed before running the following commands.

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

|Fibonacci|Main App|One Isolate|Three Isolates|IsolateManager.runFunction|IsolateManager.run|Isolate.run|
|:-:|-:|-:|-:|-:|-:|-:|
|30|551,928|541,882|195,646|553,949|547,982|538,820|
|33|2,273,956|2,268,299|816,148|2,288,071|2,282,269|2,271,376|
|36|9,761,067|9,669,422|3,453,328|9,643,678|9,606,443|9,648,076|

- **Chrome (with Worker support, JS compiler)**

|Fibonacci|Main App|One Isolate|Three Isolates|IsolateManager.runFunction|IsolateManager.run|Isolate.run (Unsupported)|
|:-:|-:|-:|-:|-:|-:|-:|
|30|2,274,100|573,900|211,700|1,160,800|1,181,800|0|
|33|9,493,100|2,330,900|821,400|2,860,800|2,866,300|0|
|36|40,051,000|9,756,200|3,452,100|10,281,200|10,270,300|0|

- **Chrome (with Worker support, WASM compiler)**

|Fibonacci|Main App|One Isolate|Three Isolates|IsolateManager.runFunction|IsolateManager.run|Isolate.run (Unsupported)|
|:-:|-:|-:|-:|-:|-:|-:|
|30|242,701|552,800|200,300|1,099,100|1,081,800|0|
|33|1,027,300|2,315,700|819,800|2,863,700|2,852,600|0|
|36|4,396,300|9,709,700|3,446,300|10,284,000|10,375,800|0|

[Detailed benchmark info](https://github.com/lamnhan066/isolate_manager/tree/v6/benchmark)

## Contributions

If you encounter issues or have suggestions for improvements, please open an issue or submit a pull request. If you appreciate this work, consider buying me a coffee:

[![BMC QR](https://raw.githubusercontent.com/lamnhan066/isolate_manager/main/assets/images/bmc_qr.png)](https://www.buymeacoffee.com/lamnhan066)
