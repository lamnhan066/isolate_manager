# Isolate Manager

## **Features**

* Easy to create multiple isolates for a function, keep it active and communicate with it.

* Supports `Worker` on Web (`Worker` is the real Isolate on Web). The plugin will use `Future` (and `Stream`) if `Worker` is unavailable on the working browser or is not configured.

* Multiple `compute`s are allowed because the plugin will queue the input data and sends it to free isolate later.

## **Basic Usage** (Use build-in function)

There are multiple ways to use this package, the only thing to notice is that the `function` has to be a `static` or `top-level` function to make it works.

### **Step 1:** Create a top-level or static function

``` dart
double add(dynamic value) => value[0] + value[1];
```

### **Step 2:** Create IsolateManager instance for that function

``` dart
final isolateManager = IsolateManager.create(
  add, // Function that you want to compute
  numOfIsolates: 4, // Number of concurrent isolates. Default is 1
);
```

### **Step 3:** Initialize the instance

``` dart
await isolateManager.start();
```

### **Step 4:** Send and receive data

You can listen to the result as `stream`

``` dart
isolateManager.stream.listen((result) => print(result));
```

You can send even more times then `numOfIsolates` because the plugin will queues the input data and sends it to free isolate later.

``` dart
// add([10, 20])
final result = await isolateManager.compute([10, 20]);
```

Build your widget with `StreamBuilder`

``` dart
StreamBuilder(
  stream: isolateManager.stream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Text('Result of the `add` function: ${snapshot.data}');
  },
),
```

### **Step 5:** Restart the `IsolateManager` if you need it

``` dart
await isolateManager.restart();
```

### **Step 6:** Stop `IsolateManager` when it finishes work

``` dart
await isolateManager.stop();
```

## **Advanced Usage** (Use your own function)

You can control everything with this method when you want to create multiple isolates for a function.

### **Step 1:** Create a function of this form

``` dart
// Create your own function here
void isolateFunction(dynamic params) {
  // Initial the controller for child isolate
  final controller = IsolateManagerController<double>(
    params, 
    onDispose: () {
      print('Dispose isolateFunction');
    }
  );

  // Get your initialParams.
  // Notice that this `initialParams` different from the `params` above.
  final initialParams = controller.initialParams;

  // Listen to the message receiving from main isolate
  controller.onIsolateMessage.listen((message) {
    // Do your stuff here
    final result = add(message[0], message[1]);
    
    // Send value back to your main process in stream [onMessage]
    controller.sendResult(result);
  });
}
```

### **Step 2:** Create IsolateManager instance for your own function

``` dart
final isolateManager = IsolateManager.createOwnIsolate(
    isolateFunction,
    initialParams: 'This is initialParams',
    debugMode: true,
  );
```

### **Step 3:** Now you can use everything as above from this step

## Worker Configuration

* **Step 1:** Download [isolate_manager/worker/worker.dart](https://raw.githubusercontent.com/vursin/isolate_manager/main/worker/worker.dart) or copy the below code to the file named `worker.dart`:

  <details>
  
  <summary>worker.dart</summary>

  ``` dart
  // ignore_for_file: avoid_web_libraries_in_flutter, depend_on_referenced_packages

  import 'dart:async';
  import 'dart:convert';
  import 'dart:html' as html;
  import 'dart:js' as js;

  import 'package:js/js.dart' as pjs;
  import 'package:js/js_util.dart' as js_util;

  @pjs.JS('self')
  external dynamic get globalScopeSelf;

  /// dart compile js worker.dart -o worker.js -O4

  /// In most cases you don't need to modify this function
  main() {
    callbackToStream('onmessage', (html.MessageEvent e) {
      return js_util.getProperty(e, 'data');
    }).listen((message) async {
      final Completer completer = Completer();
      completer.future.then((value) => jsSendMessage(value));
      completer.complete(worker(message));
    });
  }

  /// TODO: Modify your function here
  FutureOr<dynamic> worker(dynamic message) {
    // Best way to use this method is encoding the result to JSON
    // before sending to the main app, then you can decode it back to
    // the return type you want with `workerConverter`.
    return jsonEncode(message);
  }

  /// Internal function
  Stream<T> callbackToStream<J, T>(
      String name, T Function(J jsValue) unwrapValue) {
    var controller = StreamController<T>.broadcast(sync: true);
    js_util.setProperty(js.context['self'], name, js.allowInterop((J event) {
      controller.add(unwrapValue(event));
    }));
    return controller.stream;
  }

  /// Internal function
  void jsSendMessage(dynamic m) {
    js.context.callMethod('postMessage', [m]);
  }
  ```

  </details>

* **Step 2:** Modify the function `FutureOr<dynamic> worker(dynamic message)` in the script to serves your purposes. You can also use the `top-level or static function` that you have created above.

 **You should copy that function to separated file or copy to `worker.dart` file to prevent the `dart compile js` error because some other functions depend on flutter library.**

* **Step 3:** Run `dart compile js worker.dart -o worker.js -O4` to compile dart to js (-O0 to -O4 is the obfuscated level of `js`).
* **Step 4:** Copy `worker.js` to web folder (the same folder with `index.html`).
* **Step 5:** Now you can add `worker` to `workerName` like below:

  ``` dart
  final isolateManager = IsolateManager.create(
      add,
      workerName: 'worker', // Don't need to add the extension
    );
  ```

  Now the plugin will handle all other action to make the real isolate works on Web.

## Additional

* If the `worker.dart` show errors for `js` package, you can add `js` to `dev_dependencies`:
  
  ``` dart
  dev_dependencies:
    js:
  ```

* The result that you get from the isolate (or Worker) is sometimes different from the result that you want to get from the return type in the main app, you can use `converter` and `workerConverter` parameters to convert the result received from the `Isolate` (converter) and `Worker` (workerConverter). Example:

  ``` dart
  final isolateManager = IsolateManager.create(
    convertToMap,
    // Ex: 'map_result' if the name is 'map_result.js'
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

## Contributions

* This plugin as an enhanced plugin for `isolate_contactor`: [pub](https://pub.dev/packages/isolate_contactor) | [git](https://github.com/vursin/isolate_contactor)
* If you encounter any problems or feel the library is missing a feature, feel free to open an issue. Pull request are also welcome.

## To-do list

* Find the best way to prevent using `dart compile js`.
