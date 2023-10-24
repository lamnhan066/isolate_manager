// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager_example/functions.dart';
import 'package:isolate_manager_example/models/complex_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final isolateFibonacciFuture = IsolateManager.create(
    isDebug: true,
    fibonacciFuture,
    workerName: 'fibonacci',
    concurrent: 2,
  );
  final isolateIsolateFunction = IsolateManager.createOwnIsolate(
    concurrent: 2,
    isolateFunction,
    isDebug: true,
  );
  final isolateFibonacciRescursive = IsolateManager.create(
    fibonacciRescusiveFuture,
    concurrent: 2,
  );
  final isolateFunctionName = IsolateManager.create(
    functionName,
    workerName: 'function_name',
    isDebug: true,
  );
  final isolateCountEven = IsolateManager.create(
    countEven,
    isDebug: true,
  );
  final isolateError = IsolateManager.create(
    error,
    concurrent: 1,
    isDebug: true,
  );

  final isolateProgress = IsolateManager<String, String>.createOwnIsolate(
    isolateProgressFunction,
    isDebug: true,
  );

  final isolateComplexFunction = IsolateManager.create(
    complexFunction,
    workerName: 'complex',
    isDebug: true,
  );

  final isolateFetchAndDecode = IsolateManager.create(
    fetchAndDecode,
    isDebug: true,
  );

  int value1 = 2;
  int value2 = 3;
  int value3 = 4;
  int value4 = 5;
  int value5 = 1000000000;
  int progress = 0;
  String progressFinalResult = '';

  bool isLoading = true;
  Random rad = Random();

  @override
  void initState() {
    initial();
    super.initState();
  }

  @override
  void dispose() {
    isolateFibonacciFuture.stop();
    isolateIsolateFunction.stop();
    isolateFibonacciRescursive.stop();
    isolateFunctionName.stop();
    isolateCountEven.stop();
    isolateError.stop();
    isolateProgress.stop();
    super.dispose();
  }

  Future<void> initial() async {
    await isolateFibonacciFuture.start();
    await isolateIsolateFunction.start();
    await isolateFibonacciRescursive.start();
    await isolateFunctionName.start();
    await isolateCountEven.start();
    await isolateError.start();
    await isolateProgress.start();

    setState(() => isLoading = false);
  }

  void calculateFibonacciFuture([int max = 100]) {
    value1 = rad.nextInt(max);
    print('Isolate 1: Calculate fibonancci at F$value1');
    isolateFibonacciFuture.sendMessage(value1);
  }

  void calculateIsolateFunction([int max = 100]) {
    value2 = rad.nextInt(max);
    print('Isolate 2: Calculate fibonancci at F$value2');
    isolateIsolateFunction.sendMessage(value2);
  }

  void calculateFibonacciRescursive([int max = 30]) {
    value3 = rad.nextInt(max);
    print('Isolate 3: Calculate fibonancci at F$value3');
    isolateFibonacciRescursive.sendMessage(value3);
  }

  void calculateFunctionName([int max = 30]) {
    value4 = rad.nextInt(max);
    print('Isolate 3: Calculate fibonancci at F$value4');
    isolateFunctionName.sendMessage(value4);
  }

  void calculateCountEven() {
    isolateCountEven.compute(value5);
  }

  void calculateComplexFunction() {
    final param = ComplexModelParam(
      name: 'Lyo',
      age: 30,
      hobbies: ['playing games', 'reading books', 'watching TV'],
    );
    isolateComplexFunction.sendMessage(param.toJson());
  }

  void callErrorFunction() async {
    await isolateError.start();

    try {
      await isolateError.compute(0);
    } on StateError catch (e) {
      print('>> $e');
    } catch (e) {
      print('>>> $e');
    }

    await Future.delayed(const Duration(seconds: 3));
  }

  void callIsolateProgress() async {
    setState(() {
      progress = 0;
    });
    bool callback(String value) {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      if (decoded.containsKey('progress')) {
        int toInt(dynamic value) {
          if (value is int) return value;
          return int.parse(value.toString());
        }

        setState(() {
          progress = toInt(decoded['progress']);
        });

        print(value);

        // Mark this value is not the final result
        return false;
      }

      return true;
    }

    await isolateProgress.compute('Done', callback: callback);
  }

  void callFetchAndDecode() async {
    const url = 'https://pub.lamnhan.dev/isolate-manager/example-json.json';
    isolateFetchAndDecode.sendMessage(url);
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
                        stream: isolateFibonacciFuture.stream,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            isolateFibonacciFuture.sendMessage(value1);
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
                          onPressed: () => calculateFibonacciFuture(),
                          child: const Text('Calculate new Fibonacci'),
                        ),
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: () {
                            isolateFibonacciFuture.restart();
                          },
                          child: const Text('Restart isolate 1'),
                        ),
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: () {
                            isolateFibonacciFuture.stop();
                          },
                          child: const Text('Terminate isolate 1'),
                        ),
                      ),
                      StreamBuilder(
                        stream: isolateIsolateFunction.stream,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            isolateIsolateFunction.sendMessage(value2);
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
                          onPressed: () => calculateIsolateFunction(),
                          child: const Text('Calculate new Fibonacci'),
                        ),
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: () {
                            isolateIsolateFunction.restart();
                          },
                          child: const Text('Restart isolate 2'),
                        ),
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: () {
                            isolateIsolateFunction.stop();
                          },
                          child: const Text('Terminate isolate 2'),
                        ),
                      ),
                      StreamBuilder(
                        stream: isolateFibonacciRescursive.stream,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            isolateFibonacciRescursive.sendMessage(value3);
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
                          onPressed: () => calculateFibonacciRescursive(),
                          child: const Text('Calculate new Fibonacci'),
                        ),
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: () {
                            isolateFibonacciRescursive.restart();
                          },
                          child: const Text('Restart isolate 3'),
                        ),
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: () {
                            isolateFibonacciRescursive.stop();
                          },
                          child: const Text('Terminate isolate 3'),
                        ),
                      ),
                      StreamBuilder(
                        stream: isolateFunctionName.stream,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            isolateFunctionName.sendMessage(value4);
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
                          onPressed: () => calculateFunctionName(),
                          child: const Text('Calculate new Fibonacci'),
                        ),
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: () => calculateCountEven(),
                          child: const Text('Count'),
                        ),
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: callErrorFunction,
                          child: const Text('Error'),
                        ),
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: callIsolateProgress,
                          child: StreamBuilder(
                            stream: isolateProgress.stream,
                            builder: (_, snapshot) {
                              if (!snapshot.hasData) {
                                return const Text('Isolate Progress');
                              }

                              return Text('Isolate Progress: ${snapshot.data}');
                            },
                          ),
                        ),
                        subtitle: LinearProgressIndicator(
                          value: progress / 100,
                        ),
                      ),
                      ListTile(
                        title: ElevatedButton(
                          onPressed: calculateComplexFunction,
                          child: StreamBuilder(
                            stream: isolateComplexFunction.stream,
                            builder: (_, snapshot) {
                              if (!snapshot.hasData) {
                                return const Text('Isolate Complex Parameters');
                              }

                              final result = ComplexModelResult.fromJson(
                                  snapshot.data as String);

                              return Text(result.messages.join('\n'));
                            },
                          ),
                        ),
                      ),

                      /// This functions do not Work on the Web
                      if (!kIsWeb) ...[
                        ListTile(
                          title: ElevatedButton(
                            onPressed: callFetchAndDecode,
                            child: StreamBuilder(
                              stream: isolateFetchAndDecode.stream,
                              builder: (_, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Text('Isolate Fetch And Decode');
                                }

                                return Text(snapshot.data!.toString());
                              },
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
