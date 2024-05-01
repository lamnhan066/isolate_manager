# Isolate Manager

[![codecov](https://codecov.io/gh/lamnhan066/isolate_manager/graph/badge.svg?token=MSREWDRA4E)](https://codecov.io/gh/lamnhan066/isolate_manager)

## **Features**

- An easy way to create multiple long-lived (keep it active to send and receive data) isolates for a function.

- Supports `Worker` on the Web (`Worker` is the real Isolate on the Web). The plugin will use `Future` (and `Stream`) if  the `Worker` is unavailable in the working browser or is not configured.

- Supports `WASM` on the Web.

- Multiple `compute` operations are allowed because the plugin will queue the input data and send it to a free isolate later.

- Supports `try-catch` blocks.

- If you don't need to control your own function, you can use [isolates_helper](https://pub.dev/packages/isolates_helper) - a simpler version of this package that allows you to compute with multiple functions.

## **Benchmark**

- VM

|Fibonacci|Main App|One Isolate|Three Isolates|Isolate.run|
|:-:|-:|-:|-:|-:|
|30|470941|477477|171081|486789|
|33|1964361|1985924|706867|2006519|
|36|8327773|8327912|2994311|8434936|

- Chrome (With `Worker` supported)

|Fibonacci|Main App|One Worker|Three Workers|Isolate.run (Unsupported)|
|:-:|-:|-:|-:|-:|
|30|1334900|341799|121000|0|
|33|5705399|1394500|501401|0|
|36|24165201|5924900|2115500|0|

[See here](https://github.com/lamnhan066/isolate_manager/blob/main/test/benchmark_test.dart) for details.

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

### **Step 1:** Create a Worker file

Create a `worker.dart` file with this content

``` dart
import 'package:isolate_manager/isolate_manager.dart';

main() {
  // The function `fetchAndDecode` MUST NOT depend on any Flutter library
  IsolateManagerFunction.workerFunction(
    fetchAndDecode,
    onInitial: () {
      // This is optional.
      //
      // You have to set the parameter `autoInitialze` in the `create` and `createCustom` 
      // to `false` when using this.
    }
  );
}
```

### **Step 2:** Compile to JS

Run `dart compile js worker.dart -o worker.js -O4` to compile Dart to JS (The flag `-O4` is the obfuscated level of `JS`, the lowest value is `-O0` and the highest value is `-O4`)

### **Step 3:** Copy to the Web folder

Copy `worker.js` to the `Web` folder (the same folder with `index.html`)

### **Step 4:** Add it to the `IsolateManager`

Update the `isolateManager` like below

``` dart
final isolateManager = IsolateManager.create(
    fetchAndDecode,
    workerName: 'worker', // The name of the file, don't need to add the extension
    autoInitialize: true, // `true` by default. Set to `false` if you're using the `onInitial` in the Step 1.
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
       // This event can be a `Future` but you need to set the `autoInitialize` in
       // the `create` and `createCustom` to `false` to make it works.
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
  IsolateManagerFunction.customFunction<int, int>(
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
      return 0;
    },
    onInitial: (controller, initialParams) {
       // This event will be executed before all the other events
       //
       // This event can be a `Future` but you need to set the `autoInitialize` in
       // the `create` and `createCustom` to `false` to make it works.
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
    autoInitialize: true, // `true` by default. Set to `false` if you're using Future in the `onInitial` in the Step 1.
    debugMode: true,
  );
```

Now you can use everything as the **Basic Usage**.

### Additional features

- You can use `try-catch` to catch exceptions:

``` dart
try {
  final result = await isolateManager.compute('https://path/to/json.json');
} on Exception catch (e1) {
  print(e1);
} catch (e2) {
  print(e2);
}
```

- You can even manage the final result by using this callback, useful when you create your own function that needs to send the progress value before returning the final result (look at the example in the method `isolateProgressFunction` for more details):

``` dart
final result = await isolateManager.compute('https://path/to/json.json',
      callback: (value) {
        // Condition to recognize the progress value. Ex:
        final decoded = jsonDecode(value);
        if (decoded.containsKey('progress')) {
          print(decoded['progress']);

          // Mark this value as not the final result
          return false;
        }

        print('The final result is: $value');
        // Mark this value as the final result and send it into the `result`.
        return true;
      }
    )
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
