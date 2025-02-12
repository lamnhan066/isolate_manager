# Isolate Manager

[![codecov](https://codecov.io/gh/lamnhan066/isolate_manager/graph/badge.svg?token=MSREWDRA4E)](https://codecov.io/gh/lamnhan066/isolate_manager)

[![Pub Version](https://img.shields.io/pub/v/isolate_manager)](https://pub.dev/packages/isolate_manager)
[![Pub Points](https://img.shields.io/pub/points/isolate_manager)](https://pub.dev/packages/isolate_manager)
[![Pub Downloads](https://img.shields.io/pub/dm/isolate_manager)](https://pub.dev/packages/isolate_manager)
[![Pub Likes](https://img.shields.io/pub/likes/isolate_manager)](https://pub.dev/packages/isolate_manager)

## **Features**

- Supports to create multiple Isolates for:
  - **A single Function:** One `IsolateManager` instance can be used for only one Function, so that the `stream` can be used easily when using something like a `StreamBuilder` (Use the`@isolateManagerWorker` and `@isolateManagerCustomWorker` annotations).
  - **Multiple Functions:** One `IsolateManagerShared` instance can be used for multiple Functions, it's good for computing multiple Functions and doesn't care much about the `stream` (Use the `@isolateManagerSharedWorker` annotation).
- Supports `Worker` on the Web. If the `Worker` is unavailable in the working browser or is not configured, the `Future` (and `Stream`) will be used.
- Supports `WASM` compilation on the Web.
- Supports `try-catch` blocks.
- Multiple `compute` operations are allowed because the plugin will queue the input data and send it to a free isolate later.

## **Table Of Contents**

- [Benchmark](#benchmark)
- [Setup](#setup)
- [Isolate Manager Shared (For Multiple Functions)](#isolatemanagershared-method)
- [Isolate Manager (For A Single Function)](#isolatemanager-method)
  - [Basic Usage](#basic-usage)
  - [Custom Function Usage](#custom-function-usage)
  - [Progress Values (Receives multiple values from a single `compute`)](#progress-values)
- [Strategy Of The Queue](#strategy-of-the-queue)
  - [Compute a priority computation](#compute-a-priority-computation)
  - [Max number of Queues](#max-number-of-queues)
  - [How a new computation is added if the max queues is exceeded](#how-a-new-computation-is-added-if-the-max-queues-is-exceeded)
  - [Create a custom strategy](#create-a-custom-strategy)
- [Try Catch Block](#try-catch-block)
- [Progress Values](#progress-values)
- [Complicated List, Map Functions](#complicated-list-map-functions)
- [The Generator Options And Flags](#the-generator-options-and-flags)
- [Addtional Information](#additional-information)
- [Contributions](#contributions)

## **Benchmark**

Execute a recursive Fibonacci function 70 times, computing the sequence for the numbers 30, 33, and 36. The results are in microseconds (On Macbook M1 Pro 14-inch 16Gb RAM).

- VM

|Fibonacci|Main App|One Isolate|Three Isolates|Isolate.run|
|:-:|-:|-:|-:|-:|
|30|751,364|771,142|274,854|769,588|
|33|3,189,873|3,185,798|1,152,083|3,214,685|
|36|13,510,136|13,540,763|4,873,100|13,766,930|

- Chrome (With `Worker` supported)

|Fibonacci|Main App|One Worker|Three Workers|Isolate.run (Unsupported)|
|:-:|-:|-:|-:|-:|
|30|2,125,101|547,800|195,101|0|
|33|9,083,800|2,286,899|803,599|0|
|36|38,083,500|9,575,899|3,383,299|0|

[See here](https://github.com/lamnhan066/isolate_manager/blob/main/test/benchmark_test.dart) for the test details.

## **Setup**

A function used for the Isolate **MUST BE** a `static` or `top-level` function. The `@pragma('vm:entry-point')` annotation also should be added to this function to ensure that tree-shaking doesn't remove the code since it would be invoked on the native side.

```dart
@pragma('vm:entry-point')
int add(List<int> values) {
  return values[0] + values[1];
}
```

### Mobile and Desktop

- No additional setup.

### Web

- Compiling to a Javascript Worker is required to use a real Isolate (via Worker) on the Web platform. Without it, the function will be run as an asynchronous function so the UI can be frozen.
- In this instruction, the built-in generator will be used to compile the annotated function into Javascript Worker automatically.
- **Required Note:** If you want to build functions into Javascript Worker:
  - These functions **MUST NOT** depend on any Flutter library like `dart:ui`, `material`,... The best way is to move these functions into a separate file so we can control the imports easily.
  - The input parameters and the return type of these functions should be a `JSON` (or Dart primitive types) to make the `Worker` work properly.

## **IsolateManagerShared Method**

```dart
void main() async {
  // Create 3 isolateShared to solve the problems
  final isolateShared = IsolateManager.createShared(
    concurrent: 3, 

    // Remove this line (or set it to `false`) if you don't want to use the Worker
    useWorker: true, 

    // Add this mappings so we can ignore the `workerName` parameter 
    // when using the `compute` method.
    workerMappings: {
      addFuture : 'addFuture', 
      add : 'add',
    }  
  );


  // Compute the values. The return type and parameter type will respect the type
  // of the function.
  final added = await isolateShared.compute(
    addFuture, 
    [1.1, 2.2], 
    // workerFunction: 'addFuture', // Ignored because the `workerMappings` is specified
  );
  print('addFuture: 1.1 + 2.2 = $added');

  // Compute the values. The return type and parameter type will respect the type
  // of the function.
  final added = await isolateShared.compute(
    add, 
    [1, 2], 
    // workerFunction: 'add', // Ignored because the `workerMappings` is specified
  );
  print('add: 1 + 2 = $added');
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

Run this command to generate a Javascript Worker (named `$shared_worker.js` inside the `web` folder):

```console
dart run isolate_manager:generate
```

Add flag `--shared` if you want to generate only for the `IsolateManagerShared`.

## **IsolateManager Method**

### **Basic Usage**

There are multiple ways to use this package. The only thing to notice is that the `function` has to be a `static` or `top-level` function.

``` dart
main() async {
  final isolate = IsolateManager.create(
      fibonacci, 

      // And the name of the function if you want to use the Worker.
      // Otherwise, you can ignore this parameter.
      workerName: 'fibonacci',
      concurrent: 2,
    );

  isolate.stream.listen((value) {
    print(value);
  });

  final fibo = await isolate(20);
}

@isolateManagerWorker // Remove this annotation if you don't want to use the Worker
int fibonacci(int n) {
  if (n == 0) return 0;
  if (n == 1) return 1;

  return fibonacci(n - 1) + fibonacci(n - 2);
}
```

Run this command to generate a Javascript Worker:

```console
dart run isolate_manager:generate
```

Add flag `--single` if you want to generate only for the `IsolateManager`.

You can restart or stop the isolate using this method:

``` dart
await isolateManager.restart();
await isolateManager.stop();
```

## **Custom Function Usage**

You can control everything with this method when you want to create multiple isolates for a function.

### **Step 1:** Create a function of this form

Let it automatically handles the result and the Exception:

``` dart
@isolateManagerCustomWorker // Remove this line if you don't want to use the Worker
void customIsolateFunction(dynamic params) {
  IsolateManagerFunction.customFunction<int, int>(
    params,
    onEvent: (controller, message) {
      /* This event will be executed every time the `message` is received from the main isolate */
      return fibonacci(message);
    },
    onInitial: (controller, initialParams) {
       /* This event will be executed before all the other events and only one time. */
    },
    onDispose: (controller) {
       /* This event will be executed after all the other events and should NOT be a `Future` event */
    },
  );
}
```

Handle the result and the Exception by your self:

```dart
@isolateManagerCustomWorker // Remove this line if you don't want to use the Worker
void customIsolateFunction(dynamic params) {
  IsolateManagerFunction.customFunction<Map<String, dynamic>, String>(
    params,
    onEvent: (controller, message) {
      // This event will be executed every time the `message` is received from the main isolate.
      try {
        final result = fibonacci(message);
        controller.sendResult(result);
      } catch (err, stack) {
        controller.sendResultError(IsolateException(err, stack));
      }

      // Just returns something that unused to complete this method.
      return 0;
    },
    onInitial: (controller, initialParams) {
       /* This event will be executed before all the other events. */
    },
    onDispose: (controller) {
       /* This event will be executed after all the other events. */
    },
    autoHandleException: false,
    autoHandleResult: false,
  );
}
```

### **Step 2:** Create an IsolateManager instance for your own function

``` dart
final isolateManager = IsolateManager.createCustom(
    customIsolateFunction,
    initialParams: 'This is the initialParams',

    // And the name of the function if you want to use the Worker.
    // Otherwise, you can ignore this parameter.
    workerName: 'customIsolateFunction',
    debugMode: true,
  );
```

Now you can use everything as the **Basic Usage**.

## Strategy Of The Queue

### Compute a priority computation

When you have a computation that you want to compute as soon as possible, you can change the `priority` parameter to `true` to promote it to the top of the Queue.

### Max number of Queues

You can set the maximum number of the queued computations for an `IsolateManager` or `IsolateManagerShared` by changing the `maxCount` value.

If the `maxCount` is <= 0, the max number of the queued computations is unlimited.

### How a new computation is added if the max queues is exceeded

When creating a new `IsolateManager` or `IsolateManagerShared`, you can define the `queueStrategy` to control how new computations are added to or retrieved from the queue. There are four fundamental strategies:

```dart
/// Unlimited queued computations (default).
QueueStrategyUnlimited()

/// Remove the newest computation if the [maxCount] is exceeded.
QueueStrategyRemoveNewest();

/// Remove the oldest computation if the [maxCount] is exceeded.
QueueStrategyRemoveOldest()

/// Discard the new incoming computation if the [maxCount] is exceeded.
QueueStrategyDiscardIncoming()
```

### Create a custom strategy

You can extend the `QueueStrategy` and use the `queues`, `maxCount` and `queuesCount` to create your own strategy. These are how the basic strategies are created:

```dart
class QueueStrategyUnlimited<R, P> extends QueueStrategy<R, P> {
  /// Unlimited queued computations.
  QueueStrategyUnlimited();

  @override
  bool continueIfMaxCountExceeded() {
    // It means the current computation should be added to the Queue
    // without doing anything with the `queues`.
    return true; 
  }
}

class QueueStrategyRemoveNewest<R, P> extends QueueStrategy<R, P> {
  /// Remove the newest computation if the [maxCount] is exceeded.
  QueueStrategyRemoveNewest({super.maxCount = 0});

  @override
  bool continueIfMaxCountExceeded() {
    // Remove the last computation if the Queue (mean the newest one).
    queues.removeLast();
    // It means the current computation should be added to the Queue.
    return true; 
  }
}

class QueueStrategyRemoveOldest<R, P> extends QueueStrategy<R, P> {
  /// Remove the oldest computation if the [maxCount] is exceeded.
  QueueStrategyRemoveOldest({super.maxCount = 0});

  @override
  bool continueIfMaxCountExceeded() {
    // Remove the first computation if the Queue (mean the oldest one).
    queues.removeFirst();
    // It means the current computation should be added to the Queue.
    return true;
  }
}

class QueueStrategyDiscardIncoming<R, P> extends QueueStrategy<R, P> {
  /// Discard the new incoming computation if the [maxCount] is exceeded.
  QueueStrategyDiscardIncoming({super.maxCount = 0});

  @override
  bool continueIfMaxCountExceeded() {
    // It means the current computation should NOT be added to the Queue.
    return false;
  }
}
```

## Try-Catch Block

You can use `try-catch` to catch exceptions:

``` dart
try {
  final result = await isolate(-10);
} on SomeException catch (e1) {
  print(e1);
} catch (e2) {
  print(e2);
}
```

## Progress Values

You can even manage the final result by using this callback, useful when you create your own function that needs to send the progress value before returning the final result:

``` dart
main() {
  // Create an IsolateManager instance.
  final isolateManager = IsolateManager.createCustom(progressFunction);

  // Get the result.
  final result = await isolateManager.compute(100, callback: (value) {
    // Condition to recognize the progress value. Ex:
    final data = jsonDecode(value);

    if (data.containsKey('progress')) {
      print('This is a progress value: ${data['progress']}');

      // Return `false` to mark this value is not the final.
      return false;
    }

    print('This is a final value: ${data['result']}');

    // Return `true` to mark this value is the final.
    return true;
  });

  print(result); // 100
}

// This is a progress function
@isolateManagerCustomWorker // Add this anotation for a custom function
void progressFunction(dynamic params) {
  IsolateManagerFunction.customFunction<String, int>(
    params,
    onEvent: (controller, message) {
      // This value is sent as the progress values.
      for (int i = 0; i < message; i++) {
        final progress = jsonEncode({'progress' : messsage});
        controller.sendResult(progress);
      }

      // This is a final value.
      return jsonEncode({'result' : messsage});
    },
  );
}
```

## Complicated List, Map Functions

- The result that you get from the isolate (or Worker) is sometimes different from the result that you want to get from the return type in the main app, you can use `converter` and `workerConverter` parameters to convert the result received from the `Isolate` (converter) and `Worker` (workerConverter). Example:

  1. `List`

      ```dart
      main() async {
        final isolate = IsolateManager.create(
          aList,
          workerName: 'aList',
          isDebug: true,
        );

        final list = ['a', 'b', 'c'];
        final result = await isolate.compute(list);
        expect(result, equals(list));
      }

      @isolateManagerSharedWorker
      @isolateManagerWorker
      List aList(List params) {
        return params;
      }
      ```

  2. `Map`

      ``` dart
      main() async {
        final isolate = IsolateManager.create(
          aMap,
          workerName: 'aMap',
          isDebug: true,
        );
        await isolate.start();

        final map = {'a': '1', 'b': 2, 'c': 3};
        final result = await isolate.compute(map);
        expect(result, equals(map));
      }

      @isolateManagerSharedWorker
      @isolateManagerWorker
      Map aMap(Map params) {
        return params;
      }
      ```

  **Data flow:** Main -> Isolate or Worker -> **Converter** -> Result

## The Generator Options And Flags

- `--single`: Generates single Functions only.
- `--shared`: Generates shared Functions only.
- `--in <path>` (or `-i <path>`): Inputted folder.
- `--out <path>` (or `-o <path>`): Outputted folder.
- `--obfuscate <level>`: The obfuscated level of JS (0 to 4). The default is set to `4`.
- `--debug`: Keeps the temp files for debugging.
- If you want to add options or flags to the Dart to Js Compiler, you can add a `--` flag before adding those options and flags. Please note that all the arguments after the `--` flag will be passed directly into the Dart to Js Compiler. For instance:

  ```shell
  dart run isolate_manager:generate --single -i test -out test -- -Dkey1=value1 -Dkey2=value2
  ```

- **[Experiment]**: Automatically generate the `workerMappings` for both `IsolateManager` and `IsolateManagerShared` by adding a `--worker-mappings-experiment=lib/main.dart` flag to the generator. Here are the steps of the generator:

  1. Generate a `_addWorkerMappings` method at the end of the `lib/main.dart`.
  2. Add all worker mappings by using `IsolateManager.addWorkerMapping` method.
  3. Add the `_addWorkerMappings` method to the beginning of the `main` method.

## Additional Information

- Use `queuesLength` to get the current number of queued computation.
- Use `ensureStarted` to able to wait for the `start` method to finish when you want to call the `start` method manually without `await` and wait for it later.
- Use `isStarted` to check if the `start` method is completed or not.
- All above examples use `top-level` functions so the `workerName` will be the same as the function name. If you use `static` functions, you have to add the class name like `ClassName.functionName` to the `workerName` parameter. For instance:

  ```dart
  class MyIsolateFuncs {
    @isolateManagerWorker
    static String isolateFunc(String params) {
      return params;
    }
  }
  ```

  Then the `IsolateManager` should be:

  ```dart
  final isolate = IsolateManager.create(
    MyIsolateFuncs.isolateFunc,
    workerName: 'MyIsolateFuncs.isolateFunc',
  );
  ```

## Contributions

- If you encounter any problems or feel the library is missing a feature, feel free to open an issue. Pull requests are also welcome.
- If you like my work or the free stuff on this channel and want to say thanks, or encourage me to do more, you can buy me a coffee. Thank you so much!
- PR Notes:
  - After you make something changes, you can run `test/bin/run.sh` to run all needed tests (the generator included).
  - When you want to make a PR, you must discard changes in all generated files (`.js` files inside the test) to keep to the original files for backward compatibility testing.

  [![BMC QR](https://raw.githubusercontent.com/lamnhan066/isolate_manager/main/assets/images/bmc_qr.png)](https://www.buymeacoffee.com/lamnhan066)
