# Isolate Manager

[![codecov](https://codecov.io/gh/lamnhan066/isolate_manager/graph/badge.svg?token=MSREWDRA4E)](https://codecov.io/gh/lamnhan066/isolate_manager)

[![Pub Version](https://img.shields.io/pub/v/isolate_manager)](https://pub.dev/packages/isolate_manager)
[![Pub Points](https://img.shields.io/pub/points/isolate_manager)](https://pub.dev/packages/isolate_manager)
[![Pub Popularity](https://img.shields.io/pub/popularity/isolate_manager)](https://pub.dev/packages/isolate_manager)
[![Pub Likes](https://img.shields.io/pub/likes/isolate_manager)](https://pub.dev/packages/isolate_manager)

## **Features**

- Supports to create multiple Isolates for **a single Function** or **multiple Functions**.
- A generator to generate all Workers by using the `@isolateManagerWorker` and `@isolateManagerCustomWorker` annotations for **a single Function** or `@isolateManagerSharedWorker` annotation for **multiple Functions**.
- Supports `Worker` on the Web (If the `Worker` is unavailable in the working browser or is not configured, the `Future` (and `Stream`) will be used).
- Supports `WASM` compilation on the Web.
- Multiple `compute` operations are allowed because the plugin will queue the input data and send it to a free isolate later.
- Supports `try-catch` blocks.

## **Table Of Contents**

- [Benchmark](#benchmark)
- [Isolate Manager Shared (For Multiple Functions)](#isolatemanagershared-method)
- [Isolate Manager (For A Single Function)](#isolatemanager-method)
  - [Basic Usage](#basic-usage)
  - [Custom Function Usage](#custom-function-usage)
  - [Progress Values (Receives multiple values in a single `compute`)](#progress-values)
- [Try Catch Block](#try-catch-block)
- [Addtional Information](#additional-information)
- [Contributions](#contributions)

## **Benchmark**

Execute a recursive Fibonacci function 70 times, computing the sequence for the numbers 30, 33, and 36. The results are in microseconds (On Macbook M1 Pro 14-inch).

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

## **IsolateManagerShared Method**

*This method currently doesn't support the `IsolateManagerFunction.customFunction`.*

```dart
void main() async {
  // Create 3 isolateShared to solve the problems
  final isolateShared = IsolateManager.createShared(
    concurrent: 3, 
    useWorker: true

    // Add this mappings so we can ignore the `workerName` parameter 
    // when using the `compute` method.
    workerMappings: {
      addFuture : 'addFuture', 
      add : 'add',
    }  
  );

  // Listen for the results from the stream.
  isolateShared.stream.listen((result) {
    if (result is double) {
      print('Stream get addFuture: $result');
    } else {
      print('Stream get add: $result');
    }
  });

  // Compute the values. The return type and parameter type will respect the type
  // of the function.
  final added = await isolateShared.compute(
    addFuture, [1.1, 2.2], 
    workerFunction: 'addFuture', // Ignore this if the `workerMappings` is specified
  );
  print('add: 1.1 + 2.2 = $added');

  // Multiple computations at the same time are allowed. It will be queued
  // automatically.
  for (int i = 0; i < 10; i++) {
    isolateShared(
      add, 
      [i, i], 
      workerFunction: 'add', // Ignore this if the `workerMappings` is specified
    ).then((value) async {
      print('add: $i + $i = $value');
    });
  }

  // Stop the IsolateHelper instance after 5 seconds
  Timer(Duration(seconds: 5), () {
    isolateShared.stop();
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
```

Run this command to generate a Javascript Worker (named `$shared_worker.js` inside the `web` folder):

```console
dart run isolate_manager:generate_shared
```

## **IsolateManager Method**

### **Basic Usage**

There are multiple ways to use this package. The only thing to notice is that the `function` has to be a `static` or `top-level` function.

``` dart
main() async {
  final isolate = IsolateManager.create(
      fibonacci, 
      workerName: 'fibonacci', // Add this line
      concurrent: 2,
    );

  isolate.stream.listen((value) {
    print(value);
  });

  final fibo = await isolate(20);
}

@isolateManagerWorker // Add this anotation
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
@isolateManagerCustomWorker // Add this anotation for a custom function
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
@isolateManagerCustomWorker // Add this anotation for a custom function
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
    workerName: 'customIsolateFunction',
    debugMode: true,
  );
```

Now you can use everything as the **Basic Usage**.

## try-catch Block

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

## Additional Information

- The function has to be a `static` or `top-level` function.
- Use `queuesLength` to get the current number of queued computation.
- Use `ensureStarted` to able to wait for the `start` method to finish when you want to call the `start` method manually without `await` and wait for it later.
- Use `isStarted` to check if the `start` method is completed or not.
- The result that you get from the isolate (or Worker) is sometimes different from the result that you want to get from the return type in the main app, you can use `converter` and `workerConverter` parameters to convert the result received from the `Isolate` (converter) and `Worker` (workerConverter). Example:

  1. `List<String>`

      ```dart
      main() async {
        final isolate = IsolateManager.create(
          aStringList,
          workerName: 'aStringList',
          // Cast to List<String>
          workerConverter: (value) => value.cast<String>() as List<String>,
          isDebug: true,
        );

        final listString = ['a', 'b', 'c'];
        final result = await isolate.compute(listString);
        expect(result, listString);
      }

      @isolateManagerWorker
      List<String> aStringList(List<String> params) {
        return params;
      }
      ```

  2. `Map<String, int>`: Use `json` for the complicated cases

      ``` dart
      main() async {
        final isolate = IsolateManager.create(
          aStringIntMap,
          workerName: 'aStringIntMap',
          isDebug: true,
        );
        await isolate.start();

        final map = {'a': 1, 'b': 2, 'c': 3};
        final result = await isolate.compute(jsonEncode(map));
        expect(jsonDecode(result), map);
      }

      @isolateManagerWorker
      String aStringIntMap(String params) {
        return params;
      }
      ```

  **Data flow:** Main -> Isolate or Worker -> **Converter** -> Result

- If you want to use Worker more effectively, convert all parameters and results to JSON (or String) before sending them.

## Contributions

- If you encounter any problems or feel the library is missing a feature, feel free to open an issue. Pull requests are also welcome.

- If you like my work or the free stuff on this channel and want to say thanks, or encourage me to do more, you can buy me a coffee. Thank you so much!

  [![BMC QR](https://raw.githubusercontent.com/lamnhan066/isolate_manager/main/assets/images/bmc_qr.png)](https://www.buymeacoffee.com/lamnhan066)
