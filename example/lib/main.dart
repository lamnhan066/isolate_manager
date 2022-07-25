// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:isolate_manager/isolate_manager.dart';

void main() {
  runApp(const MyApp());
}

/// This must be a static or top-level function
///
/// This function is very expensive to calculate, so I can test for un-blocking UI feature
Future<int> fibonacciRescusiveFuture(dynamic n) async {
  if (n == 0) return 0;
  if (n <= 2) return 1;

  // Magic code: This is only for non-blocking UI on Web platform
  await Future.delayed(Duration.zero);

  return await fibonacciRescusiveFuture(n - 1) +
      await fibonacciRescusiveFuture(n - 2);
}

/// This must be a static or top-level function
Future<int> fibonacciFuture(dynamic n) async {
  if (n == 0) return 0;
  if (n <= 2) return 1;

  double n1 = 0, n2 = 1, n3 = 1;

  for (int i = 2; i <= n; i++) {
    n3 = n1 + n2;
    n1 = n2;
    n2 = n3;

    // Magic code: This is only for non-blocking UI on Web platform
    await Future.delayed(Duration.zero);
  }

  return n3.round();
}

/// This must be a static or top-level function
int fibonacci(dynamic n) {
  if (n == 0) return 0;
  if (n == 1 || n == 2) return 1;

  int n1 = 0, n2 = 1, n3 = 1;

  for (int i = 2; i <= n; i++) {
    n3 = n1 + n2;
    n1 = n2;
    n2 = n3;
  }

  return n3.round();
}

void isolateFunction(dynamic params) {
  final channel = IsolateManagerController<int>(params);
  channel.onIsolateMessage.listen((message) async {
    // Do more stuff here

    final result = await fibonacciFuture(message);

    // Send the result to your [onMessage] stream
    channel.sendResult(result);
  });
}

dynamic functionName(dynamic message) => message;

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final IsolateManager<int> isolateManager1 = IsolateManager.create(
    isDebug: true,
    fibonacciFuture,
    workerName: 'fibonacci',
    numOfIsolates: 2,
  );
  final IsolateManager<int> isolateManager2 = IsolateManager.createOwnIsolate(
    numOfIsolates: 2,
    isolateFunction,
    isDebug: true,
  );
  late IsolateManager<int> isolateManager3 = IsolateManager.create(
    fibonacciRescusiveFuture,
    numOfIsolates: 2,
  );
  late IsolateManager isolateManager4 = IsolateManager.create(
    functionName,
    workerName: 'function_name',
    isDebug: true,
  );
  int value1 = 2;
  int value2 = 3;
  int value3 = 4;
  int value4 = 5;

  bool isLoading = true;
  Random rad = Random();

  @override
  void initState() {
    initial();
    super.initState();
  }

  @override
  void dispose() {
    isolateManager1.stop();
    isolateManager2.stop();
    isolateManager3.stop();
    isolateManager4.stop();
    super.dispose();
  }

  Future<void> initial() async {
    await isolateManager1.start();
    await isolateManager2.start();
    await isolateManager3.start();
    await isolateManager4.start();

    setState(() => isLoading = false);
  }

  void calculateValue1([int max = 100]) {
    value1 = rad.nextInt(max);
    print('Isolate 1: Calculate fibonancci at F$value1');
    isolateManager1.sendMessage(value1);
  }

  void calculateValue2([int max = 100]) {
    value2 = rad.nextInt(max);
    print('Isolate 2: Calculate fibonancci at F$value2');
    isolateManager2.sendMessage(value2);
  }

  void calculateValue3([int max = 30]) {
    value3 = rad.nextInt(max);
    print('Isolate 3: Calculate fibonancci at F$value3');
    isolateManager3.sendMessage(value3);
  }

  void calculateValue4([int max = 30]) {
    value4 = rad.nextInt(max);
    print('Isolate 3: Calculate fibonancci at F$value4');
    isolateManager4.sendMessage(value4);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Multi Isolate Fibonacci'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      StreamBuilder(
                        stream: isolateManager1.onMessage,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            isolateManager1.sendMessage(value1);
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return Text(
                              'Isolate1: Fibonacci at F$value1 = ${snapshot.data}');
                        },
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: () => calculateValue1(),
                          child: const Text('Calculate new Fibonacci'),
                        ),
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: () {
                            isolateManager1.restart();
                          },
                          child: const Text('Restart isolate 1'),
                        ),
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: () {
                            isolateManager1.stop();
                          },
                          child: const Text('Terminate isolate 1'),
                        ),
                      ),
                      StreamBuilder(
                        stream: isolateManager2.onMessage,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            isolateManager2.sendMessage(value2);
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return Text(
                              'Isolate2: Fibonacci at F$value2 = ${snapshot.data}');
                        },
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: () => calculateValue2(),
                          child: const Text('Calculate new Fibonacci'),
                        ),
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: () {
                            isolateManager2.restart();
                          },
                          child: const Text('Restart isolate 2'),
                        ),
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: () {
                            isolateManager2.stop();
                          },
                          child: const Text('Terminate isolate 2'),
                        ),
                      ),
                      StreamBuilder(
                        stream: isolateManager3.onMessage,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            isolateManager3.sendMessage(value3);
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return Text(
                              'Isolate3: Fibonacci at F$value3 = ${snapshot.data}');
                        },
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: () => calculateValue3(),
                          child: const Text('Calculate new Fibonacci'),
                        ),
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: () {
                            isolateManager3.restart();
                          },
                          child: const Text('Restart isolate 3'),
                        ),
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: () {
                            isolateManager3.stop();
                          },
                          child: const Text('Terminate isolate 3'),
                        ),
                      ),
                      StreamBuilder(
                        stream: isolateManager4.onMessage,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            isolateManager4.sendMessage(value4);
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return Text(
                              'Isolate4: Value of $value4 = ${snapshot.data}');
                        },
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: () => calculateValue4(),
                          child: const Text('Calculate new Fibonacci'),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
