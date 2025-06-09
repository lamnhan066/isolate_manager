# Isolate Manager

[![codecov](https://codecov.io/gh/lamnhan066/isolate_manager/graph/badge.svg?token=MSREWDRA4E)](https://codecov.io/gh/lamnhan066/isolate_manager)
[![Pub Version](https://img.shields.io/pub/v/isolate_manager)](https://pub.dev/packages/isolate_manager)
[![Pub Points](https://img.shields.io/pub/points/isolate_manager)](https://pub.dev/packages/isolate_manager)
[![Pub Downloads](https://img.shields.io/pub/dm/isolate_manager)](https://pub.dev/packages/isolate_manager)
[![Pub Likes](https://img.shields.io/pub/likes/isolate_manager)](https://pub.dev/packages/isolate_manager)

[![PubStats Popularity](https://pubstats.dev/badges/packages/isolate_manager/popularity.svg)](https://pubstats.dev/packages/isolate_manager)
[![PubStats Rank](https://pubstats.dev/badges/packages/isolate_manager/rank.svg)](https://pubstats.dev/packages/isolate_manager)
[![PubStats Dependents](https://pubstats.dev/badges/packages/isolate_manager/dependents.svg)](https://pubstats.dev/packages/isolate_manager)

**Isolate Manager** is a powerful Flutter/Dart package designed to simplify concurrent programming using isolates. It offers robust cross-platform support, including native, web (via JavaScript Workers), and WebAssembly (WASM).

## Why Isolate Manager?

* **Effortless Concurrency:** Takes the complexity out of Dart's isolates for smooth background processing.
* **Truly Cross-Platform:** Write your concurrent code once and run it seamlessly on Dart VM, Web (auto-compiles to JS Workers), and WASM.
* **Robust & Safe:** Provides built-in type and exception safety mechanisms, especially crucial for web worker communication.
* **Optimized Performance:** Features smart task queuing, priority handling, and customizable strategies to fine-tune execution.
* **Flexible Isolate Types:** Choose from one-off, multi-function, or single-function isolates to best suit your task's lifecycle.

## Features

* **Versatile Isolate Management:**
  * **One-off Isolates:** Perfect for single, intensive computations. Supports web workers.
  * **Multi-Function Isolates:** Reuse a single isolate for various functions, minimizing overhead.
  * **Single-Function Isolates:** Dedicate an isolate to a specific, continuous task or data stream.
* **Cross-Platform by Design:**
  * **Web & WASM Ready:** Automatically compiles isolate functions into JavaScript Workers for web deployment.
  * **Graceful Fallback:** Defaults to `Future`/`Stream` if Web Workers are unavailable.
* **Intelligent Queue System:**
  * Automatic task queuing.
  * Support for priority tasks.
  * Customizable queue overflow strategies.
* **Type & Exception Safety:**
  * Utilize specialized `ImType` wrappers (`ImNum`, `ImString`, etc.) for reliable data transfer with web workers.
  * Propagate custom exceptions across isolate boundaries, even on the web.
* **Developer-Friendly Extras:**
  * **Custom Isolate Functions:** Gain full control over the isolate's lifecycle and communication.
  * **Progress Reporting:** Send intermediate updates from long-running tasks.
  * **Codeless Web Workers:** Generate necessary JavaScript worker files without `build_runner`.
  * **Built-in Benchmark:** Compare performance of different concurrency models.

## Getting Started

### 1. Add Dependencies

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  isolate_manager: ^latest_version # Use the latest version

dev_dependencies:
  isolate_manager_generator: ^latest_version # Required for web worker generation
```

Then, run `dart pub get` or `flutter pub get`.

### 2. Important Prerequisite for Isolate Functions

Functions intended to run in an isolate **must** be:

* A `static` method within a class, OR
* A top-level function (defined outside any class).

Additionally, annotate these functions with `@pragma('vm:entry-point')` to prevent them from being removed by tree-shaking during compilation.

> **Note:** Worker annotations like `@isolateManagerWorker`, `@isolateManagerSharedWorker`, and `@isolateManagerCustomWorker` are provided by the `isolate_manager` package.
> Make sure to import them if you use them in your code.

```dart
import 'package:isolate_manager/isolate_manager.dart';

@pragma('vm:entry-point')
int sum(List<int> numbers) {
  return numbers.reduce((a, b) => a + b);
}
```

### 3. Platform-Specific Setup

#### Mobile & Desktop (VM)

No additional setup is required!

#### Web (JavaScript Workers)

To use isolates on the web, your Dart functions need to be compiled into JavaScript Workers.

* **Annotate Your Functions:**
  Use specific annotations on the functions you want to be available as web workers. Run the generator after adding or modifying these.

  * `@isolateManagerWorker`: For one-off or single-function isolates.
  * `@isolateManagerSharedWorker`: For shared, multi-function isolates.
  * `@isolateManagerCustomWorker`: For custom isolate functions where you manage communication manually.

* **Data Transfer Limitations:**

  * Functions for web workers must **not** depend on Flutter-specific libraries (e.g., `dart:ui`).
  * Only Dart primitives (`num`, `String`, `bool`, `null`), and `Map` or `List` collections containing these primitives, are directly transferable.
  * For other data types, use the provided [`ImType` wrappers](#ensuring-type-safety-web) or serialize/deserialize your data manually.

* **Generate JS Workers:**
  Run the following command in your terminal:

  ```shell
  dart run isolate_manager:generate
  ```

  (See [Web Worker Generator](#web-worker-generator) for more options.)

#### WebAssembly (WASM) Notes

* **Type Handling:** When using WASM, all `int` types (including those in collections) are treated as `double`. Isolate Manager provides a built-in converter to handle this automatically; you can disable it by setting `enableWasmConverter: false` if needed.
* **Development Server Headers:** If your app hangs when running with `flutter run -d chrome --wasm`, you might need to set specific headers. Try:

  ```shell
  flutter run -d chrome --wasm --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp
  ```

## Usage Examples

### One-off Isolate (Simple Task)

Ideal for fire-and-forget computations.

```dart
import 'package:isolate_manager/isolate_manager.dart';

@pragma('vm:entry-point')
@isolateManagerWorker // For web worker generation
int fibonacciRecursive(int n) {
  if (n < 2) return n;
  return fibonacciRecursive(n - 1) + fibonacciRecursive(n - 2);
}

void main() async {
  // Option 1: Explicit worker parameters (useful if function name differs or for clarity)
  final result1 = await IsolateManager.run(
    () => fibonacciRecursive(40),     // The actual function to execute
    workerName: 'fibonacciRecursive', // Name used for JS worker mapping
    workerParameter: 40,              // Parameter for the JS worker
  );
  print('Fibonacci(40) - Option 1: $result1');

  // Option 2: Automatic worker mapping (concise)
  final result2 = await IsolateManager.runFunction(fibonacciRecursive, 40);
  print('Fibonacci(40) - Option 2: $result2');
}
```

### Long-Lived Multi-Function Isolate

Reuse a single isolate for multiple different computations.

```dart
import 'package:isolate_manager/isolate_manager.dart';

@pragma('vm:entry-point')
@isolateManagerSharedWorker
Future<double> addNumbersFuture(List<double> values) async {
  return values[0] + values[1];
}

@pragma('vm:entry-point')
@isolateManagerSharedWorker
int multiplyNumbers(List<int> values) {
  return values[0] * values[1];
}

void main() async {
  final sharedIsolate = IsolateManager.createShared(
    concurrent: 2,   // Number of tasks this isolate can handle concurrently
    useWorker: true, // Enable web worker usage if on web
    workerMappings: {
      // Map Dart function references to their JS worker names
      addNumbersFuture: 'addNumbersFuture',
      multiplyNumbers: 'multiplyNumbers',
    },
  );

  // Optional: Listen for intermediate values (if any function sends them)
  sharedIsolate.stream.listen((value) {
    print('Intermediate value from shared isolate: $value');
  });

  final sumResult = await sharedIsolate.compute(addNumbersFuture, [10.5, 20.3]);
  print('Sum (shared): 10.5 + 20.3 = $sumResult');

  final productResult = await sharedIsolate.compute(multiplyNumbers, [7, 6]);
  print('Product (shared): 7 * 6 = $productResult');

  await sharedIsolate.stop(); // Important to release resources
  // Or use `sharedIsolate.restart()` to restart the isolate
}
```

### Long-Lived Single-Function Isolate

Dedicate an isolate to a single, potentially continuous, function.

```dart
import 'package:isolate_manager/isolate_manager.dart';

@pragma('vm:entry-point')
@isolateManagerWorker
int complexCalculation(int initialValue) {
  // Simulate a task that might send progress updates or run for a while
  int result = initialValue;
  for (int i = 0; i < 5; i++) {
    result += i * 2;
    // If this were a custom function, you could send progress here
  }
  return result;
}

void main() async {
  final singleFuncIsolate = IsolateManager.create(
    complexCalculation, // The function this isolate is dedicated to
    workerName: 'complexCalculation', // For JS worker
    concurrent: 1, // Typically 1 for a single dedicated function
  );

  // Optional: Listen for intermediate values
  singleFuncIsolate.stream.listen((value) {
    print('Intermediate value from single-function isolate: $value');
  });

  final calculationResult = await singleFuncIsolate.compute(10); // `compute` is callable
  print('Complex Calculation Result: $calculationResult');

  await singleFuncIsolate.stop(); // Release resources
  // Or use `singleFuncIsolate.restart()` to restart the isolate
}
```

### Custom Function & Error Handling

For fine-grained control over the isolate's behavior, including sending multiple results or handling initialization/disposal.

```dart
import 'dart:convert';
import 'package:isolate_manager/isolate_manager.dart';

@pragma('vm:entry-point')
@isolateManagerWorker // For web
int fibonacci(int n) {
  if (n < 0) throw ArgumentError('Input cannot be negative.');
  if (n < 2) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}

@pragma('vm:entry-point')
@isolateManagerCustomWorker
void customFibonacciWorker(dynamic params) {
  IsolateManagerFunction.customFunction<int, int>(
    params,
    onEvent: (controller, message) {
      try {
        final result = fibonacci(message);
        controller.sendResult(result); // Send the final result
      } catch (err, stack) {
        // Send an IsolateException for structured error handling
        controller.sendResultError(IsolateException(err.toString(), stack.toString()));
      }
      return 0; // Indicates completion for this event
    },
    onInit: (controller) {
      print('Custom Fibonacci Worker: Initialized');
      // Perform any setup logic here
    },
    onDispose: (controller) {
      print('Custom Fibonacci Worker: Disposed');
      // Perform any cleanup logic here
    },
    autoHandleException: false, // Set to true to let IsolateManager handle basic errors
    autoHandleResult: false,    // Set to true to let IsolateManager handle basic result sending
  );
}

void main() async {
  final customIsolate = IsolateManager.createCustom(
    customFibonacciWorker,
    workerName: 'customFibonacciWorker', // For JS Worker
    debugMode: true, // Enable more logging
  );

  try {
    final result = await customIsolate.compute(10);
    print('Custom Fibonacci(10): $result');

    final resultNegative = await customIsolate.compute(-5); // This will throw
    print('Custom Fibonacci(-5): $resultNegative');
  } on IsolateException catch (e) {
    print('Caught IsolateException: ${e.error}');
    // print('Stack trace: ${e.stacktrace}');
  } catch (e) {
    print('Caught other error: $e');
  } finally {
    await customIsolate.stop();
  }
}
```

## Advanced Capabilities

### Smart Queue Management

Control how tasks are queued and processed when multiple requests are made to an isolate.

* **Priority Tasks:** Add `priority: true` when calling `compute` or `run` to move a task to the front of its queue.

* **Queue Size Limit:** Set `maxCount` in `IsolateManager.create`, `createShared`, or `createCustom` constructors to limit the number of pending tasks.

* **Queue Strategies:** Define behavior when `maxCount` is reached:

  * `UnlimitedStrategy()`: (Default) No limit on queued tasks.
  * `DropNewestStrategy()`: Removes the most recently added task.
  * `DropOldestStrategy()`: Removes the oldest task in the queue.
  * `RejectIncomingStrategy()`: Rejects any new tasks if the queue is full.

* **Custom Queue Strategy:** For custom logic, extend `QueueStrategy<R, P>`:

  ```dart
  class MyCustomStrategy<R, P> extends QueueStrategy<R, P> {
    @override
    bool continueIfMaxCountExceeded() {
      // Access `queues`, `queuesCount`, `maxCount`
      if (queuesCount >= maxCount && queues.isNotEmpty) {
        // Example: Allow if the oldest task is low priority (pseudo-code)
        // if (queues.first.priority == false) {
        //   print('Custom strategy: Dropping oldest to make space.');
        //   queues.removeFirst(); // You'd need to manage this carefully
        //   return true; // Allow the new task
        // }
        return false; // Reject by default if full
      }
      return true; // Allow if not full
    }
  }
  ```

  *Note: Modifying `queues` directly in `continueIfMaxCountExceeded` requires careful implementation to ensure consistency.*

### Progress Updates

Receive intermediate results from a task before it completes. This is typically used with `IsolateManager.createCustom`.

> In this example, progress updates are sent as JSON strings for demonstration purposes.

```dart
// In your main Dart code:
void main() async {
  final isolate = IsolateManager.createCustom(
    longRunningTaskWithProgress,
    workerName: 'longRunningTaskWithProgress', // For JS Worker
  );

  print('Starting task with progress updates...');
  final result = await isolate.compute(
    100, // Example parameter for the task
    callback: (dynamic value) {
      // `value` is what `controller.sendResult()` sends from the isolate
      try {
        final data = jsonDecode(value as String); // Assuming JSON string for progress
        if (data.containsKey('progress')) {
          print('Progress: ${data['progress']}%');
          return false; // Indicates this is a progress update, not the final result
        } else if (data.containsKey('finalResult')) {
          print('Final result package received: ${data['finalResult']}');
          return true; // Indicates this is the final result
        }
      } catch (e) {
        print('Error decoding progress/result: $e');
        return true; // Treat as error, stop listening
      }
      return true; // Default to stop if format is unexpected
    },
  );

  print('Task completed with final processed value: $result');
  await isolate.stop();
}

// In your isolate function (e.g., custom worker):
@pragma('vm:entry-point')
@isolateManagerCustomWorker
void longRunningTaskWithProgress(dynamic params) {
  IsolateManagerFunction.customFunction<String, int>(
    params,
    onEvent: (controller, totalSteps) {
      for (int i = 0; i <= totalSteps; i += 10) {
        final progressReport = jsonEncode({'progress': i});
        controller.sendResult(progressReport); // Send progress update
      }
      // Send the final result
      return jsonEncode({'finalResult': totalSteps});
    },
  );
}
```

### Ensuring Type Safety (Web)

When working with Web Workers, data transfer is restricted. `IsolateManager` provides `ImType` wrappers for common types to ensure they are correctly (de)serialized.

```dart
import 'package:isolate_manager/isolate_manager.dart';

@pragma('vm:entry-point')
@isolateManagerWorker
ImMap processDataWeb(ImList numbers) {
  // 1. Unwrap to get standard Dart types (List<dynamic> in this case)
  final nativeList = numbers.unwrap as List<dynamic>;

  // 2. Process the data
  final processedMap = <ImType, ImType>{};
  for (var i = 0; i < nativeList.length; i++) {
    final numVal = nativeList[i] as num; // Ensure type
    processedMap[ImString('item_$i')] = ImNum(numVal * 2);
  }

  // 3. Wrap the result in an ImType
  return ImMap(processedMap);
}

void main() async {
  // On web, this will use the JS worker if generated.
  final isolate = IsolateManager.create(
    processDataWeb,
    workerName: 'processDataWeb',
  );

  try {
    // 1. Wrap your input data
    final inputData = ImList.wrap([1, 2.5, 3]);

    // 2. Compute
    final ImMap result = await isolate.compute(inputData) as ImMap;

    // 3. Unwrap the result
    final nativeResult = result.unwrap as Map<dynamic, dynamic>;
    nativeResult.forEach((key, value) {
      print('Web Processed: ${key} -> ${value}');
    });

  } on UnsupportedImTypeException catch (e) {
    print('Error: Unsupported type used with ImType. ${e.message}');
  } catch (e) {
    print('An error occurred: $e');
  } finally {
    await isolate.stop();
  }
}
```

**Available `ImType` wrappers (for non-nullable types only):**

* `ImNum(double value)` / `ImNum(int value)`
* `ImString(String value)`
* `ImBool(bool value)`
* `ImList(List<ImType> value)` or `ImList.wrap(List<dynamic> nativeList)`
* `ImMap(Map<ImType, ImType> value)` or `ImMap.wrap(Map<dynamic, dynamic> nativeMap)`

An `UnsupportedImTypeException` is thrown if `ImList.wrap` or `ImMap.wrap` encounters a type that cannot be converted.

### Handling Exceptions (Web)

To ensure custom exceptions are correctly propagated from Web Workers:

1. **Define a Custom IsolateException:** Extend `IsolateException`.
2. **Register the Exception:** Use `IsolateManager.registerException()` in your main application.
3. **Throw the Custom Exception:** In your isolate function.

```dart
import 'package:isolate_manager/isolate_manager.dart';

// 1. Define your custom exception
class MyCustomWebException extends IsolateException {
  const MyCustomWebException(super.error, [super.stacktrace]);

  @override
  String get name => 'MyCustomWebException'; // Crucial for deserialization
}

@pragma('vm:entry-point')
@isolateManagerWorker
ImNum taskThatThrowsCustom(ImNum input) {
  if (input.unwrap == 0) {
    throw const MyCustomWebException('Input cannot be zero!');
  }
  return ImNum(100 / (input.unwrap as num));
}

void main() async {
  // 2. Register the exception type (typically in your app's initialization)
  IsolateManager.registerException(
    (message, stackTrace) => MyCustomWebException(message, stackTrace),
  );

  final isolate = IsolateManager.create(
    taskThatThrowsCustom,
    workerName: 'taskThatThrowsCustom', // For JS Worker
  );

  try {
    print('Trying with valid input...');
    final result = await isolate.compute(ImNum(10));
    print('Result: ${(result as ImNum).unwrap}'); // Should be 10

    print('\nTrying with input that causes custom exception...');
    await isolate.compute(ImNum(0)); // This will throw
  } on MyCustomWebException catch (e, s) {
    print('Caught MyCustomWebException!');
    print('Error: ${e.error}');
    // print('Stack: $s'); // s is the stacktrace from the main isolate
    // print('Original Isolate Stack: ${e.stacktrace}'); // stacktrace from the worker
  } catch (e) {
    print('Caught an unexpected error: $e');
  } finally {
    await isolate.stop();
  }
}
```

## Add a Worker Mapping Once

Typically done during app initialization:

```dart
IsolateManager.addWorkerMapping(
  fibonacciRecursive,      // Dart function
  'fibonacciRecursive',    // Generated JS-worker file name
);
IsolateManager.addWorkerMapping(addNumbersFuture, 'addNumbersFuture');
```

Use the mapped function:

```dart
// No boilerplate — the manager already knows which worker to spin up.
await IsolateManager.runFunction(fibonacciRecursive, 40);
await sharedIsolate.compute(addNumbersFuture, [10.5, 20.3]);
await singleFuncIsolate.compute(10);
```

If you’re wondering what “magic” was removed:

```dart
// Long form (now unnecessary):
// final result = await IsolateManager.run(
//   () => fibonacciRecursive(40),
//   workerName: 'fibonacciRecursive',
//   workerParameter: 40,
// );
```

## Web Worker Generator

Use the `isolate_manager:generate` command to compile annotated Dart functions into JavaScript workers for web deployment.
See [Web (JavaScript Workers)](#web-javascript-workers) for web platform setup.

**Command:**

```shell
dart run isolate_manager:generate
```

**Flags & Options:**

* `--single`: Generate only for functions annotated with `@isolateManagerWorker`.
* `--shared`: Generate only for functions annotated with `@isolateManagerSharedWorker`.
* `--in <path>` (or `-i <path>`): Specify the input directory to scan for annotated functions (default: `lib`).
* `--out <path>` (or `-o <path>`): Specify the output directory for generated JS files (default: `web`).
* `--obfuscate <level>`: Set JavaScript obfuscation level (0-4, default is 4 for smallest size). 0 means no obfuscation.
* `--debug`: Retain temporary files created during generation for debugging purposes.
* `--worker-mappings-experiment=lib/main.dart` (Experimental): Attempt to auto-generate `workerMappings` for `IsolateManager.createShared` by scanning the specified Dart file.

## Additional Tips

* **Queue Length:** Check `isolateManagerInstance.queuesLength` to get the current number of tasks in the queue.
* **Manual Start Control:** Use `isolateManagerInstance.ensureStarted()` to await explicit initialization if needed. Check `isolateManagerInstance.isStarted` to see if the isolate is ready.
* **Data Flow with Converters (WASM):** When WASM type converters are active, the data flow is: Main Isolate → Worker → Main Isolate → Converter → Final Result.

## Performance Benchmark

The following benchmarks demonstrate the performance of recursive Fibonacci calculations across different concurrency approaches and environments. Measurements are in microseconds (µs) on a MacBook M1 Pro 14" with 16GB RAM.

* **VM (Native)**

| Fibonacci |  Main App | One Isolate | Three Isolates | IsolateManager.runFunction | IsolateManager.run | Isolate.run |
| :-------: | --------: | ----------: | -------------: | -------------------------: | -----------------: | ----------: |
|     30    |   551,928 |     541,882 |        195,646 |                    553,949 |            547,982 |     538,820 |
|     33    | 2,273,956 |   2,268,299 |        816,148 |                  2,288,071 |          2,282,269 |   2,271,376 |
|     36    | 9,761,067 |   9,669,422 |      3,453,328 |                  9,643,678 |          9,606,443 |   9,648,076 |

* **Chrome (with Worker support, JS compiler)**

| Fibonacci |   Main App | One Isolate | Three Isolates | IsolateManager.runFunction | IsolateManager.run | Isolate.run (Unsupported) |
| :-------: | ---------: | ----------: | -------------: | -------------------------: | -----------------: | ------------------------: |
|     30    |  2,274,100 |     573,900 |        211,700 |                  1,160,800 |          1,181,800 |                         0 |
|     33    |  9,493,100 |   2,330,900 |        821,400 |                  2,860,800 |          2,866,300 |                         0 |
|     36    | 40,051,000 |   9,756,200 |      3,452,100 |                 10,281,200 |         10,270,300 |                         0 |

* **Chrome (with Worker support, WASM compiler)**

| Fibonacci |  Main App | One Isolate | Three Isolates | IsolateManager.runFunction | IsolateManager.run | Isolate.run (Unsupported) |
| :-------: | --------: | ----------: | -------------: | -------------------------: | -----------------: | ------------------------: |
|     30    |   242,701 |     552,800 |        200,300 |                  1,099,100 |          1,081,800 |                         0 |
|     33    | 1,027,300 |   2,315,700 |        819,800 |                  2,863,700 |          2,852,600 |                         0 |
|     36    | 4,396,300 |   9,709,700 |      3,446,300 |                 10,284,000 |         10,375,800 |                         0 |

For more details, see the [full benchmark information](https://github.com/lamnhan066/isolate_manager/tree/main/benchmark).

## Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/lamnhan066/isolate_manager/issues).

If you find this package helpful, consider supporting the developer:

[![BMC QR](https://raw.githubusercontent.com/lamnhan066/isolate_manager/main/assets/images/bmc_qr.png)](https://www.buymeacoffee.com/lamnhan066)
