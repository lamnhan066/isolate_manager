# Isolate Manager

[![codecov](https://codecov.io/gh/lamnhan066/isolate_manager/graph/badge.svg?token=MSREWDRA4E)](https://codecov.io/gh/lamnhan066/isolate_manager)

[![Pub Version](https://img.shields.io/pub/v/isolate_manager)](https://pub.dev/packages/isolate_manager)
[![Pub Points](https://img.shields.io/pub/points/isolate_manager)](https://pub.dev/packages/isolate_manager)
[![Pub Popularity](https://img.shields.io/pub/popularity/isolate_manager)](https://pub.dev/packages/isolate_manager)
[![Pub Likes](https://img.shields.io/pub/likes/isolate_manager)](https://pub.dev/packages/isolate_manager)

[![Discord](https://img.shields.io/discord/1240864619342594048)](https://discord.gg/V6ykuZgy)

[![BMC QR](https://raw.githubusercontent.com/lamnhan066/isolate_manager/main/assets/images/bmc_qr.png)](https://www.buymeacoffee.com/lamnhan066)

## **Features**

- A generator to generate all Workers by using the `@isolateManagerWorker` annotation.
- An easy way to create multiple long-lived isolates for a function (keep it active to send and receive data).
- Supports `Worker` on the Web (If the `Worker` is unavailable in the working browser or is not configured, the `Future` (and `Stream`) will be used instead).
- Supports `WASM` compilation on the Web.
- Multiple `compute` operations are allowed because the plugin will queue the input data and send it to a free isolate later.
- Supports `try-catch` blocks.
- To compute with multiple functions, you can use the [isolates_helper](https://pub.dev/packages/isolates_helper) instead.

## **Table Of Contents**

- [Benchmark](#benchmark)
- [Basic Usage](#basic-usage)
- [Basic Usage (With The Web Worker)](#basic-usage-with-the-web-worker)
- [Custom Function Usage](#custom-function-usage)
- [Custom Worker Usage](#custom-worker-usage)
- [Try Catch Block](#try-catch-block)
- [Progress Values (Receives multiple values in a single `compute`)](#progress-values)
- [Addtional Information](#additional-information)
- [Contributions](#contributions)
- [Migrations](#migrations)

## **Benchmark**

Execute a recursive Fibonacci function 70 times, computing the sequence for the numbers 30, 33, and 36. The results are in microseconds.

- VM

|Fibonacci|Main App|One Isolate|Three Isolates|Isolate.run|
|:-:|-:|-:|-:|-:|
|30|470,941|477,477|171,081|486,789|
|33|1,964,361|1,985,924|706,867|2,006,519|
|36|8,327,773|8,327,912|2,994,311|8,434,936|

- Chrome (With `Worker` supported)

|Fibonacci|Main App|One Worker|Three Workers|Isolate.run (Unsupported)|
|:-:|-:|-:|-:|-:|
|30|1,334,900|341,799|121,000|0|
|33|5,705,399|1,394,500|501,401|0|
|36|24,165,201|5,924,900|2,115,500|0|

[See here](https://github.com/lamnhan066/isolate_manager/blob/main/test/benchmark_test.dart) for the test details.

## **Basic Usage

There are multiple ways to use this package. The only thing to notice is that the `function` has to be a `static` or `top-level` function.

``` dart
main() async {
  final isolate = IsolateManager.create(
      fibonacci, 
      concurrent: 4
    );

  isolate.stream.listen((value) {
    print(value);
  });

  final fibo = await isolate(55);
}

int fibonacci(int n) {
  if (n == 0) return 0;
  if (n == 1) return 1;

  return fibonacci(n - 1) + fibonacci(n - 2);
}
```

You can restart or stop the isolate using this method:

``` dart
await isolateManager.restart();
await isolateManager.stop();
```

## **Basic Usage (With The Web Worker)**

There are multiple ways to use this package. The only thing to notice is that the `function` has to be a `static` or `top-level` function.

``` dart
main() async {
  final isolate = IsolateManager.create(
      fibonacci, 
      workerName: 'fibonacci', // Add this line
      concurrent: 4
    );

  isolate.stream.listen((value) {
    print(value);
  });

  final fibo = await isolate(55);
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

You can control everything with this method when you want to create multiple isolates for a function. With this method, you can also do one-time stuff (`onInitial`) when the isolate is started or each-time stuff when you call `compute` or `sendMessage`.

### **Step 1:** Create a function of this form

Let it automatically handles the result and the Exception:

``` dart
void customIsolateFunction(dynamic params) {
  IsolateManagerFunction.customFunction<int, int>(
    params,
    onEvent: (controller, message) {
      /* This event will be executed every time the `message` is received from the main isolate */
      return fibonacci(message);
    },
    onInitial: (controller, initialParams) {
       // This event will be executed before all the other events
       //
       // This event can be a `Future`.
    },
    onDispose: (controller) {
       /* This event will be executed after all the other events and should NOT be a `Future` event */
    },
  );
}
```

Handle the result and the Exception by your self:

```dart
void customIsolateFunction(dynamic params) {
  IsolateManagerFunction.customFunction<Map<String, dynamic>, String>(
    params,
    onEvent: (controller, message) {
      // This event will be executed every time the `message` is received from the main isolate.
      //
      // This event can be a `Future`.
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
       // This event will be executed before all the other events.
       //
       // This event can be a `Future`.
    },
    onDispose: (controller) {
       // This event will be executed after all the other events.
       //
       // This event should NOT be a `Future` event */
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
    debugMode: true,
  );
```

Now you can use everything as the **Basic Usage**.

## **Custom Worker Usage**

### **Use The Generator**

**Step 1:** Use a modifiable annotation

```dart
@IsolateManagerWorker('RecursiveFibonacci')
int fibonacci(int n) {
  if (n == 0) return 0;
  if (n == 1) return 1;

  return fibonacci(n - 1) + fibonacci(n - 2);
}
```

**Step 2:** Execute the generator

```console
dart run isolate_manager:generate
```

**Step 3:** Update the `IsolateManager`:

```dart
final isolate = IsolateManager.create(fibonacci, workerName: 'RecursiveFibonacci');
```

If you want to place the generated JS inside a subfolder, you can update the annotation to `@IsolateManagerWorker('workers/RecursiveFibonacci')` and update the `workerName` to `workers/RecursiveFibonacci`.

Static functions are also supported. A function `WorkerFunctions.method` will be compiled to `WorkerFunctions.method.js`, so that the `workerName` will be `WorkerFunctions.method`.

### **Manually**

**Step 1:** Create a Worker file

Create a `fibonacci.dart` file with this content

``` dart
import 'package:isolate_manager/isolate_manager.dart';

main() {
  // The function `fibonacci` MUST NOT depend on any Flutter library
  IsolateManagerFunction.workerFunction(
    fibonacci,
    onInitial: () {
      /* Optional. Run before all events */
    }
  );
}
```

**Step 2:** Compile to JS

Run `dart compile js fibonacci.dart -o fibonacci.js -O4` to compile Dart to JS (The flag `-O4` is the obfuscated level of `JS`, the lowest value is `-O0` and the highest value is `-O4`)

**Step 3:** Copy to the Web folder

Copy the `fibonacci.js` to the `Web` folder (the same folder with `index.html`)

**Step 4:** Add it to the `IsolateManager`

Update the `isolateManager` like below

``` dart
final isolateManager = IsolateManager.create(
    fibonacci,
    workerName: 'fibonacci', // The name of the file, don't need to add the extension
  );
```

Now the plugin will handle all other action to make the real isolate works on Web.

**Note:** If you want to use Worker more effectively, convert all parameters and results to JSON (or String) before sending them.

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
    if (value != 100) {
      print('This is a progress value: $value');

      // Return `false` to mark this value is not the final.
      return false;
    }

    print('This is a final value: $value');

    // Return `true` to mark this value is the final.
    return true;
  });

  print(result); // 100
}

// This is a progress function
void progressFunction(dynamic params) {
  IsolateManagerFunction.customFunction<int, int>(
    params,
    onEvent: (controller, message) {
      // This value is sent as the progress values.
      for (int i = 0; i < message; i++) {
        controller.sendResult(i);
      }

      // This is a final value.
      return message;
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
</br>

<p align='center'><a href="https://www.buymeacoffee.com/lamnhan066"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=lamnhan066&button_colour=5F7FFF&font_colour=ffffff&font_family=Cookie&outline_colour=000000&coffee_colour=FFDD00" alt="Buy me a coffee" width="200"></a></p>

## Migrations

### v5.0.0

All isolate functions MUST be update and all Workers MUST be recompiled with the following changes:

- If you're using the `IsolateManagerFunction.workerFunction`, you need to re-generate the `JS` for the Web Worker (compile from `Dart` to `JS`). If you're using the `IsolateManagerFunction.customFunction`, it will be automatically updated.

- If you're using the old method, you need to send a `initialized` signal from an `Isolate` and a `Worker`:
  - Custom function of an `Isolate`: add the `controller.initialized();` to the end of the function.
    - Before:

        ```dart
        void customFunction(dynamic params) {
          final controller = IsolateManagerController(params);
          controller.onIsolateMessage.then((value){
            // ...
          });
        }
        ```

    - After:

        ```dart
        void customFunction(dynamic params) async {
          // Do something sync or async here

          final controller = IsolateManagerController(params); 
          controller.onIsolateMessage.then((value){
            // ...
          });

          controller.initialized(); // <--
        }
        ```

  - On the Web `Worker`: add `jsSendMessage(IsolateState.initialized.toJson());` to the end of the `main` method.
    - Before:

        ```dart
        void main() {
          callbackToStream('onmessage', (MessageEvent e) {
            return js_util.getProperty(e, 'data');
          }).listen((message) {
            // ...
          });  
        }
        ```

    - After:

        ```dart
        void main() async {
          // Do something sync or async here

          callbackToStream('onmessage', (MessageEvent e) {
            return js_util.getProperty(e, 'data');
          }).listen((message) {
            // ...
          });

          jsSendMessage(IsolateState.initialized.toJson()); // <--
        }
        ```
