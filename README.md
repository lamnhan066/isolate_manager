# Isolate Manager

## Features

* Easy to create multiple isolate for a function, keep it active and comunicate with it.

* Supports `Worker` on Web (`Worker` is the real Isolate on Web). The plugin will use `Future` (and `Stream`) if `Worker` is not available on the working browser or is not configured.

* Multiple `compute`s are allowed because the plugin will queues the input data and sends it to free isolate later.

## **BASIC USAGE** *(Use build-in function)*

There are multiple ways to use this package, the only thing to notice that the `function` have to be a `static` or `top-level` function to make it works.

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
    return Text(
        'Result of the `add` function: ${snapshot.data}');
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

## **ADVANCED USAGE** *(Use your own function)*

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
  print(initialParams);

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

## CONFIGURATION FOR `WORKER`

* **Step 1:** Download [isolate_manager/worker/function_name.dart](https://raw.githubusercontent.com/vursin/isolate_manager/main/worker/function_name.dart) and rename it to the `<function_name>.dart` that you want to create isolate.
* **Step 2:** Modify the function `dynamic functionName(dynamic message)` in the script to serves your purposes, then rename it to the same as the above `<function_name>` (Just helping you easier to remember for later use). You can also use the `top-level or static function` that you have created above.

  ***You should copy that function to separated file or copy to `<function_name>.dart` file to prevent the `dart compile js` error because some other functions depend on flutter library.***

* **Step 3:** Run `dart compile js <function_name>.dart -o <function_name>.js -O4` to compile dart to js (-O0 to -O4 is the obfuscated level of `js`).
* **Step 4:** Copy `<function_name>.js` to web folder (the same folder with `index.html`).
* **Step 5:** Now you can add parameter `workerName` to your code like below:

  ``` dart
  final isolateManager = IsolateManager.create(
      add,
      workerName: '<function_name>', // Ex: 'add' if the name is 'add.js'
    );
  ```

  Now the plugin will handle all other action to make the real isolate works on Web.

## Additional

* If the `function_name.dart` show errors for `js` package, you can add `js` to `dev_dependencies`:
  
  ``` dart
  dev_dependencies:
    js: ^0.6.4
  ```

* `IsolateManager.create` and `createOwnIsolate` include `converter` and `workerConverter` parameters which helping you to convert the result received from the `Isolate` (converter) and `Worker` (workerConverter) and send it to the result. Example:

  ``` dart
  final isolateManager = IsolateManager.create(
    convertToMap,
    workerName: '<function_name>', // Ex: 'map_result' if the name is 'map_result.js'
    workerConverter: (result) {
      final Map<int, double> convert = {};

      // Convert Map<String, String> (received from Worker) to Map<int, double>
      (jsonDecode(result) as Map).forEach((key, value) => {
            convert.addAll({int.parse(key): double.parse(value)})
          });

      return convert;
    },
  );
  ```

    **Data flow:** Main -> Isolate or Worker -> *Converter* -> Result

## Contributions

* This plugin as an enhanced plugin for `isolate_contactor`: [pub](https://pub.dev/packages/isolate_contactor) | [git](https://github.com/vursin/isolate_contactor)
* If you encounter any problems or feel the library is missing a feature, please feel free to open an issue. Pull request are also welcome.

## To-do list

* [ ] Find the best way to prevent using `dart compile js`.
