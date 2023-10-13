// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager_example/functions.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final isolateManager1 = IsolateManager.create(
    isDebug: true,
    fibonacciFuture,
    workerName: 'fibonacci',
    concurrent: 2,
  );
  final isolateManager2 = IsolateManager.createOwnIsolate(
    concurrent: 2,
    isolateFunction,
    isDebug: true,
  );
  final isolateManager3 = IsolateManager.create(
    fibonacciRescusiveFuture,
    concurrent: 2,
  );
  final IsolateManager isolateManager4 = IsolateManager.create(
    functionName,
    workerName: 'function_name',
    isDebug: true,
  );
  final isolateManager5 = IsolateManager.create(
    countEven,
    isDebug: true,
  );
  final isolateManager6 = IsolateManager.create(
    error,
    concurrent: 1,
    isDebug: true,
  );

  final isolateProgress = IsolateManager<String, String>.createOwnIsolate(
    isolateProgressFunction,
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
    isolateManager1.stop();
    isolateManager2.stop();
    isolateManager3.stop();
    isolateManager4.stop();
    isolateManager5.stop();
    isolateManager6.stop();
    isolateProgress.stop();
    super.dispose();
  }

  Future<void> initial() async {
    await isolateManager1.start();
    await isolateManager2.start();
    await isolateManager3.start();
    await isolateManager4.start();
    await isolateManager5.start();
    await isolateManager6.start();
    await isolateProgress.start();

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

  void calculateValue5() {
    isolateManager5.compute(value5);
  }

  void callErrorFunction() async {
    await isolateManager6.start();

    try {
      await isolateManager6.compute(0);
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
                        stream: isolateManager1.stream,
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
                        stream: isolateManager2.stream,
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
                        stream: isolateManager3.stream,
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
                        stream: isolateManager4.stream,
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
                      ListTile(
                        title: ElevatedButton(
                          onPressed: () => calculateValue5(),
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
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
