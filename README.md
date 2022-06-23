# Isolate Manager

A plugin that helps you create multiple isolates for a function, keep it active and compute with it.

This plugin is an enhanced plugin for `isolate_contactor`: [pub](https://pub.dev/packages/isolate_contactor) | [git](https://github.com/vursin/isolate_contactor). The main difference is that it allows to create multiple isolates for a function, automatically queues the input data and sends it to free isolate later.

## **BASIC USAGE** *(Use build-in function)*

There are multiple ways to use this package, the only thing to notice that the `function` have to be a `static` or `top-level` function to make it works.

### **Step 1:** Create a top-level or static function

``` dart
double add(dynamic value) => value[0] + value[1];
```

### **Step 2:** Create IsolateManager instance for that function

``` dart
  IsolateManager<int> isolateManager = IsolateManager.createOwnIsolate(
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

### Step 6: Stop `IsolateManager` when it finishes work

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
  final controller = IsolateManagerController<double>(params);

  // Get your initialParams
  final initialParams = controller.initialParams;

  // Initial anything here. This area of codes only run once

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
IsolateManager<int> isolateManager = IsolateManager.createOwnIsolate(numOfIsolates: 4, isolateFunction: isolateFunction);
```

### **Step 3:** Now you can use everything as above from this step

## Limitation

Support web platform with limited features. The package use `Future` to provide the same features to Isolate.

## Contributions

- This plugin as an enhanced plugin for `isolate_contactor`: [pub](https://pub.dev/packages/isolate_contactor) | [git](https://github.com/vursin/isolate_contactor)
- If you encounter any problems or feel the library is missing a feature, please feel free to open an issue. Pull request are also welcome.

## To-do list

- [ ] Add real isolate for web platform with service-worker.js.
