# Isolate Manager

[![codecov](https://codecov.io/gh/lamnhan066/isolate_manager/graph/badge.svg?token=MSREWDRA4E)](https://codecov.io/gh/lamnhan066/isolate_manager)

## **Features**

- An easy way to create multiple long-lived isolates for a function (keep it active to send and receive data).

- Supports `Worker` on the Web (If the `Worker` is unavailable in the working browser or is not configured, the `Future` (and `Stream`) will be used instead).

- Supports `WASM` on the Web.

- Multiple `compute` operations are allowed because the plugin will queue the input data and send it to a free isolate later.

- Supports `try-catch` blocks.

- To compute with multiple functions, you can use the [isolates_helper](https://pub.dev/packages/isolates_helper) instead.

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

## **Basic Usage** (Use built-in function)

There are multiple ways to use this package. The only thing to notice is that the `function` has to be a `static` or `top-level` function to work.

### **Step 1:** Create a top-level or static function

``` dart
Future<Map<String, dynamic>> fetchAndDecode(String url) async {
  final response = await http.Client().get(Uri.parse(url));
  return jsonDecode(response.body);
}
```

### **Step 2:** Create an IsolateManager instance for that function

``` dart
final isolateFetchAndDecode = IsolateManager.create(
  fetchAndDecode, // Function you want to compute
  concurrent: 4, // Number of concurrent isolates. Default is 1
);
```

### **Step 3 [Optional]:** Initialize the instance; this step is not required because it's automatically called when you use `.compute` for the first time

``` dart
await isolateManager.start();
```

You can also run this method when creating the instance:

``` dart
final isolateManager = IsolateManager.create(
  fetchAndDecode, // Function you want to compute
  concurrent: 4, // Number of concurrent isolates. Default is 1
)..start();
```

### **Step 4:** Send and receive data

``` dart
final result = await isolateManager.compute('https://path/to/json.json');
```

You can send even more times than `concurrent` because the plugin will queue the input data and send it to a free isolate later.

You can listen to the result as a `stream`:

``` dart
isolateManager.stream.listen((result) => print(result));
```

Build your widget with `StreamBuilder`:

``` dart
StreamBuilder(
  stream: isolateManager.stream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Text('Data: ${snapshot.data}');
  },
),
```

### **Step 5:** Restart the `IsolateManager` if needed

``` dart
await isolateManager.restart();
```

### **Step 6:** Stop `IsolateManager` when it finishes work

``` dart
await isolateManager.stop();
```

## Worker Configuration

### Use The Generator

#### Add the annotation

```dart
@isolateManagerWorker
int add(List<int> params) {
  return params[0] + params[1];
}
```

Multiple annotated functions inside a file are supported. You need to make sure that all functions across all files will have different names because the generated JS use it to name the files. You can specify the JS's name by using the `@IsolateManagerWorker('modifiedWorkerName')` annotation.

#### Execute the generator

```console
dart run isolate_manager:generate
```

After running the command, a file named `add.js` will be generated inside the `web` folder.

#### Update the `IsolateManager`

```dart
final isolate = IsolateManager.create(add, workerName: 'add');
```

If you want to place the generated JS inside a subfolder, you can update the annotation to `@IsolateManagerWorker('workers/add')` and update the `workerName` to `workers/add`.

### Mannually

#### **Step 1:** Create a Worker file

Create a `add.dart` file with this content

``` dart
import 'package:isolate_manager/isolate_manager.dart';

main() {
  // The function `add` MUST NOT depend on any Flutter library
  IsolateManagerFunction.workerFunction(
    add,
    onInitial: () {
      /* Optional. Run before all events */
    }
  );
}
```

#### **Step 2:** Compile to JS

Run `dart compile js add.dart -o add.js -O4` to compile Dart to JS (The flag `-O4` is the obfuscated level of `JS`, the lowest value is `-O0` and the highest value is `-O4`)

#### **Step 3:** Copy to the Web folder

Copy the `add.js` to the `Web` folder (the same folder with `index.html`)

#### **Step 4:** Add it to the `IsolateManager`

Update the `isolateManager` like below

``` dart
final isolateManager = IsolateManager.create(
    add,
    workerName: 'add', // The name of the file, don't need to add the extension
  );
```

Now the plugin will handle all other action to make the real isolate works on Web.

**Note:** If you want to use Worker more effectively, convert all parameters and results to JSON (or String) before sending them.

## **Advanced Usage** (Use a custom function)

You can control everything with this method when you want to create multiple isolates for a function. With this method, you can also do one-time stuff (`onInitial`) when the isolate is started or each-time stuff when you call `compute` or `sendMessage`.

### **Step 1:** Create a function of this form

Let it automatically handles the result and the Exception:

``` dart
void customIsolateFunction(dynamic params) {
  IsolateManagerFunction.customFunction<int, int>(
    params,
    onEvent: (controller, message) {
      /* This event will be executed every time the `message` is received from the main isolate */
      return fetchAndDecode(message);
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
    onEvent: (controller, message) async {
      /* This event will be executed every time the `message` is received from the main isolate */
      try {
        final result = await fetchAndDecode(message);
        controller.sendResult(result);
      } catch (err, stack) {
        controller.sendResultError(IsolateException(err, stack));
      }

      // Just returns something that unused to complete this method.
      return {};
    },
    onInitial: (controller, initialParams) {
       // This event will be executed before all the other events
       //
       // This event can be a `Future`.
    },
    onDispose: (controller) {
       /* This event will be executed after all the other events and should NOT be a `Future` event */
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
    initialParams: 'This is initialParams',
    debugMode: true,
  );
```

Now you can use everything as the **Basic Usage**.

## try-catch Block

You can use `try-catch` to catch exceptions:

``` dart
try {
  final result = await isolateManager.compute('https://path/to/json.json');
} on Exception catch (e1) {
  print(e1);
} catch (e2) {
  print(e2);
}
```

## Progress Values

You can even manage the final result by using this callback, useful when you create your own function that needs to send the progress value before returning the final result:

``` dart
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
```

## Additional

- Use `queuesLength` to get the current number of queued computation.

- Use `ensureStarted` to able to wait for the `start` method to finish when you want to call the `start` method manually without `await` and wait for it later.

- Use `isStarted` to check if the `start` method is completed or not.

- The result that you get from the isolate (or Worker) is sometimes different from the result that you want to get from the return type in the main app, you can use `converter` and `workerConverter` parameters to convert the result received from the `Isolate` (converter) and `Worker` (workerConverter). Example:

  ``` dart
  final isolateManager = IsolateManager.create(
    convertToMap,
    // Ex: 'worker' if the name is 'worker.js'
    workerName: 'worker',
    // Convert the data from worker to fix the issue related to the different data type between dart and js
    workerConverter: (result) {
      final Map<int, double> convert = {};

      // Convert Map<String, String> (received from Worker) to Map<int, double>
      final decodedMap = jsonDecode(result) as Map;
      decodedMap.forEach((key, value) => convert.addAll({int.parse(key): double.parse(value)}));

      return convert;
    },
  );
  ```

  **Data flow:** Main -> Isolate or Worker -> **Converter** -> Result

- If you want to use Worker more effectively, convert all parameters and results to JSON (or String) before sending them.

## Contributions

- If you encounter any problems or feel the library is missing a feature, feel free to open an issue. Pull requests are also welcome.

- If you like my work or the free stuff on this channel and want to say thanks, or encourage me to do more, you can buy me a coffee. Thank you so much!
</br>

<p align='center'><a href="https://www.buymeacoffee.com/lamnhan066"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=lamnhan066&button_colour=5F7FFF&font_colour=ffffff&font_family=Cookie&outline_colour=000000&coffee_colour=FFDD00" alt="Buy me a coffee" width="200"></a></p>

## To-do list

- Find the best way to prevent using `dart compile js`.
