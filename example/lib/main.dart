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
  final isolates = IsolateManager.createShared(
    concurrent: 3,
    useWorker: true,
    workerMappings: {
      countEven: 'countEven',
      fibonacciRecursiveFuture: 'fibonacciRecursiveFuture',
      fibonacciFuture: 'fibonacciFuture',
      fibonacci: 'fibonacci',
    },
    isDebug: true,
  )..start();

  final isolateIsolateFunction = IsolateManager.createCustom(
    concurrent: 2,
    isolateFunction,
    isDebug: true,
  );

  final isolateFunctionName = IsolateManager.create(
    functionName,
    workerName: 'functionName',
    isDebug: true,
  );

  final isolateError = IsolateManager.create(
    errorFunction,
    concurrent: 1,
    isDebug: true,
  );

  final isolateProgress = IsolateManager<String?, String?>.createCustom(
    isolateProgressFunction,
    workerName: 'isolateProgressFunction',
    isDebug: true,
  );

  final isolateComplexFunction = IsolateManager.create(
    complexFunction,
    workerName: 'complexFunction',
    isDebug: true,
  );

  final isolateFetchAndDecode = IsolateManager.create(
    fetchAndDecode,
    isDebug: true,
  );

  int fibonacciFutureParam = 2;
  int fibonacciFutureResult = 0;

  int value2 = 3;

  int fibonacciRecursiveParam = 4;
  int fibonacciRecursiveResult = 0;

  int countEventResult = 0;

  String errorResult = '';

  int functionNameParam = 5;
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
    isolateIsolateFunction.stop();
    isolateFunctionName.stop();
    isolateError.stop();
    isolateProgress.stop();
    super.dispose();
  }

  Future<void> initial() async {
    await isolateIsolateFunction.start();
    await isolateFunctionName.start();
    await isolateError.start();
    await isolateProgress.start();

    setState(() => isLoading = false);
  }

  void calculateFibonacciFuture([int max = 100]) async {
    fibonacciFutureParam = rad.nextInt(max);

    final result = await isolates.compute(
      fibonacciFuture,
      fibonacciFutureParam,
    );
    setState(() {
      fibonacciFutureResult = result;
    });
  }

  void calculateIsolateFunction([int max = 100]) {
    value2 = rad.nextInt(max);
    isolateIsolateFunction.sendMessage(value2);
  }

  void calculateFibonacciRecursive([int max = 30]) async {
    fibonacciRecursiveParam = rad.nextInt(max);
    final result = await isolates.compute(
      fibonacciRecursiveFuture,
      fibonacciFutureParam,
    );
    setState(() {
      fibonacciRecursiveResult = result;
    });
  }

  void calculateFunctionName([int max = 30]) {
    functionNameParam = rad.nextInt(max);
    isolateFunctionName(functionNameParam);
  }

  void calculateCountEven() async {
    final result = await isolates.compute(
      countEven,
      fibonacciFutureParam,
    );
    setState(() {
      countEventResult = result;
    });
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
      setState(() {
        errorResult = e.toString();
      });
    } catch (e) {
      setState(() {
        errorResult = e.toString();
      });
    }

    await Future.delayed(const Duration(seconds: 3));
  }

  void callIsolateProgress() async {
    setState(() {
      progress = 0;
    });
    bool callback(String? value) {
      if (value == null) {
        print(value);
        return false;
      }

      final decoded = jsonDecode(value) as Map;
      if (decoded.containsKey('progress')) {
        int toInt(dynamic value) {
          if (value is int) return value;
          return int.parse(value.toString());
        }

        setState(() {
          progress = toInt(decoded['progress']);
        });

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
                      Card(
                        child: ListTile(
                          title: Column(
                            children: [
                              Text(
                                'Fibonacci Future: F$fibonacciFutureParam = $fibonacciFutureResult',
                              ),
                              ElevatedButton(
                                onPressed: () => calculateFibonacciFuture(),
                                child: const Text('Calculate'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: Column(
                            children: [
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
                                    'Isolate Function: F$value2 = ${snapshot.data}',
                                  );
                                },
                              ),
                              ElevatedButton(
                                onPressed: () => calculateIsolateFunction(),
                                child: const Text('Calculate'),
                              ),
                              const SizedBox(height: 6),
                              ElevatedButton(
                                onPressed: () {
                                  isolateIsolateFunction.restart();
                                },
                                child: const Text('Restart'),
                              ),
                              const SizedBox(height: 6),
                              ElevatedButton(
                                onPressed: () {
                                  isolateIsolateFunction.stop();
                                },
                                child: const Text('Terminate'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: Column(
                            children: [
                              Text(
                                'Fibonacci Recursive: F$fibonacciRecursiveParam = $fibonacciRecursiveResult',
                              ),
                              ElevatedButton(
                                onPressed: () => calculateFibonacciRecursive(),
                                child: const Text('Calculate'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: Column(
                            children: [
                              StreamBuilder(
                                stream: isolateFunctionName.stream,
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    isolateFunctionName
                                        .sendMessage(functionNameParam);
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  return Text(
                                    'Function Name: $functionNameParam = ${snapshot.data}',
                                  );
                                },
                              ),
                              ListTile(
                                title: ElevatedButton(
                                  onPressed: () => calculateFunctionName(),
                                  child: const Text('Calculate'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: Column(
                            children: [
                              Text('Count Even: $countEventResult'),
                              ElevatedButton(
                                onPressed: () => calculateCountEven(),
                                child: const Text('Count Even'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: Column(
                            children: [
                              Text('Error: $errorResult'),
                              ElevatedButton(
                                onPressed: callErrorFunction,
                                child: const Text('Error'),
                              ),
                            ],
                          ),
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
