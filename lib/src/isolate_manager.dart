import 'dart:async';

import 'package:isolate_manager/src/base/isolate_contactor.dart';
import 'package:isolate_manager/src/base/isolate_manager_shared.dart';
import 'package:isolate_manager/src/isolate_manager_function.dart';
import 'package:isolate_manager/src/models/isolate_queue.dart';
import 'package:isolate_manager/src/models/queue_strategy.dart';
import 'package:isolate_manager/src/utils/print.dart';

/// Type for the callback of the isolate.
typedef IsolateCallback<R> = FutureOr<bool> Function(R value);

/// Callback for the `createCustom`'s `function`.
typedef IsolateCustomFunction = IsolateFunction<void, dynamic>;

/// Create a new [IsolateManager] instance by using [IsolateManager.create],
/// [IsolateManager.createCustom] or [IsolateManager.createShared].
class IsolateManager<R, P> {
  /// Creates a new IsolateManager for isolate-based computations.
  ///
  /// [isolateFunction] is the function to be run in each isolate.
  ///
  /// Use [workerName] (or a pre-defined mapping in [_workerMappings]) to utilize
  /// a named worker JS file on the Web.
  ///
  /// [concurrent] decides how many isolates to spawn.
  ///
  /// [converter] and [workerConverter] optionally transform the results before returning.
  ///
  /// Control the Queue strategy via [queueStrategy] with the following basic
  /// strategies:
  ///   - [QueueStrategyUnlimited] - default.
  ///   - [QueueStrategyRemoveNewest]
  ///   - [QueueStrategyRemoveOldest]
  ///   - [QueueStrategyDiscardIncoming]
  ///
  /// [isDebug] enables debug logs when set to true.
  IsolateManager.create(
    IsolateFunction<R, P> this.isolateFunction, {
    String? workerName,
    this.concurrent = 1,
    this.converter,
    this.workerConverter,
    QueueStrategy<R, P>? queueStrategy,
    this.isDebug = false,
  })  : isCustomIsolate = false,
        initialParams = '',
        queueStrategy = queueStrategy ?? QueueStrategyUnlimited(),
        _workerName = workerName,
        _streamController = StreamController.broadcast() {
    IsolateContactor.debugLogPrefix = debugLogPrefix;
  }

  /// Creates a new [IsolateManager] instance with a custom isolate function.
  ///
  /// [isolateFunction] is the user-defined function to be run in each isolate.
  ///
  /// Use [workerName] (or a pre-defined mapping in [_workerMappings]) to utilize
  /// a named worker JS file on the Web.
  ///
  /// [concurrent] decides how many isolates to spawn.
  ///
  /// [converter] and [workerConverter] optionally transform results before returning.
  ///
  /// Control the Queue strategy via [queueStrategy] with the following basic
  /// strategies:
  ///   - [QueueStrategyUnlimited] - default.
  ///   - [QueueStrategyRemoveNewest]
  ///   - [QueueStrategyRemoveOldest]
  ///   - [QueueStrategyDiscardIncoming]
  ///
  /// Set [isDebug] to `true` to enable debug logs.
  IsolateManager.createCustom(
    IsolateCustomFunction this.isolateFunction, {
    String? workerName,
    this.initialParams,
    this.concurrent = 1,
    this.converter,
    this.workerConverter,
    QueueStrategy<R, P>? queueStrategy,
    this.isDebug = false,
  })  : isCustomIsolate = true,
        queueStrategy = queueStrategy ?? QueueStrategyUnlimited(),
        _workerName = workerName,
        _streamController = StreamController.broadcast() {
    // Set the debug log prefix.
    IsolateContactor.debugLogPrefix = debugLogPrefix;
  }

  /// Executes [computation] in a one-off isolate and returns its result.
  /// This function behaves similarly to `Isolate.run` but also supports Web Workers.
  ///
  /// When a [workerName] is provided, the corresponding Web Worker is used,
  /// and [workerParameter] is passed to the worker.
  ///
  /// Example:
  /// ```dart
  /// @isolateManagerWorker
  /// int fibonacciRecursive(int n) {
  ///   if (n == 0) return 0;
  ///   if (n == 1) return 1;
  ///   return fibonacciRecursive(n - 1) + fibonacciRecursive(n - 2);
  /// }
  ///
  /// final fibo40 = await IsolateManager.run(
  ///   () => fibonacciRecursive(40),
  ///   workerName: 'fibonacciRecursive',
  ///   workerParameter: 40,
  /// );
  /// ```
  ///
  /// Set [isDebug] to `true` to enable debug logging.
  static Future<R> run<R>(
    FutureOr<R> Function() computation, {
    String? workerName,
    Object? workerParameter,
    bool isDebug = false,
  }) {
    return runFunction<R, Object?>(
      (_) => computation(),
      workerParameter,
      workerName: workerName,
      isDebug: isDebug,
    );
  }

  /// Executes [function] in a dedicated, one-off isolate and returns its result.
  ///
  /// Use [run] when you want behavior similar to `Isolate.run`. Unlike [runFunction],
  /// this method automatically applies the [workerName] for web Workers when specified
  /// via [addWorkerMapping] or a generator.
  ///
  /// Example:
  /// ```dart
  /// @isolateManagerWorker
  /// int fibonacciRecursive(int n) {
  ///   if (n == 0) return 0;
  ///   if (n == 1) return 1;
  ///   return fibonacciRecursive(n - 1) + fibonacciRecursive(n - 2);
  /// }
  ///
  /// final result = await IsolateManager.run(fibonacciRecursive, 40);
  /// ```
  ///
  /// Set [isDebug] to `true` to enable debug logging.
  static Future<R> runFunction<R, P>(
    IsolateFunction<R, P> function,
    P parameter, {
    String? workerName,
    bool isDebug = false,
  }) async {
    final im = IsolateManager<R, P>.create(
      function,
      workerName: workerName,
      isDebug: isDebug,
    );

    await im.start();
    try {
      return await im.compute(parameter);
    } finally {
      await im.stop();
    }
  }

  /// Create multiple long live isolates for computation. This method can be used
  /// to compute multiple functions.
  ///
  /// [concurrent] is a number of isolates that you want to create.
  ///
  /// Set [useWorker] to `true` if you want to use the Worker on the Web.
  ///
  /// [workerConverter] is a converter for the worker, the data from the worker
  /// will be directly sent to this method to convert to the result format that
  /// you want to.
  ///
  /// Predefine the mapping between a function and a name of worker function
  /// using the [workerMappings], so we can ignore the `workerName` parameter
  /// when we compute a function multiple times.
  ///
  /// Set [autoStart] to `false` if you want to call the `start()` method manually.
  ///
  /// If the generated Worker is put inside a folder (such as `workers`), the [subPath]
  /// needs to be set to `workers`.
  ///
  /// Control the Queue strategy via [queueStrategy] with the following basic
  /// strategies:
  ///   - [QueueStrategyUnlimited] - default.
  ///   - [QueueStrategyRemoveNewest]
  ///   - [QueueStrategyRemoveOldest]
  ///   - [QueueStrategyDiscardIncoming]
  ///
  /// Set [isDebug] to `true` if you want to print the debug log.
  static IsolateManagerShared createShared({
    int concurrent = 1,
    bool useWorker = false,
    Object Function(dynamic)? workerConverter,
    Map<Function, String>? workerMappings,
    bool autoStart = true,
    String subPath = '',
    int maxQueueCount = 0,
    QueueStrategy<Object, List<Object>>? queueStrategy,
    bool isDebug = false,
  }) =>
      IsolateManagerShared(
        concurrent: concurrent,
        useWorker: useWorker,
        workerConverter: workerConverter,
        workerMappings: workerMappings ?? _workerMappings,
        autoStart: autoStart,
        subPath: subPath,
        queueStrategy: queueStrategy,
        isDebug: isDebug,
      );

  /// Debug logs prefix.
  static String debugLogPrefix = 'Isolate Manager';

  /// Store the global mappings between functions and Workers.
  static final _workerMappings = <Function, String>{};

  /// Adds a mapping between a function and a Worker.
  ///
  /// This method is used by the generator to associate an [IsolateFunction] with a
  /// unique worker name. If the function is already mapped and [overwrite] is `false`,
  /// an [IsolateException] will be thrown.
  ///
  /// - [function]: The function to be mapped.
  /// - [name]: The unique worker name associated with the function.
  /// - [overwrite]: If `true`, replaces an existing mapping; otherwise, throws an [IsolateException].
  static void addWorkerMapping<R, P>(
    IsolateFunction<R, P> function,
    String name, {
    bool overwrite = false,
  }) {
    final contains = _workerMappings.containsKey(function);

    if (contains && !overwrite) {
      throw IsolateException(
        'The function $function is already mapped to ${_workerMappings[function]}.',
      );
    }

    _workerMappings[function] = name;
  }

  /// Clears all worker mappings.
  ///
  /// This method removes all stored function-to-worker associations,
  /// effectively resetting the mapping. It should be used with caution,
  /// as it erases all previously registered workers.
  static void clearWorkerMappings() {
    _workerMappings.clear();
  }

  /// Number of concurrent isolates.
  final int concurrent;

  /// Isolate function.
  final Object isolateFunction;

  /// Name of the `Worker` without the extension.
  ///
  /// Ex: Worker: `worker.js` => workerName: 'worker;
  ///     Worker: `workers/worker.js` => workerName: 'workers/worker'
  String get workerName =>
      _workerName ?? _workerMappings[isolateFunction] ?? '';
  final String? _workerName;

  /// Initial parameters.
  final Object? initialParams;

  /// Is using your own isolate function.
  final bool isCustomIsolate;

  /// Allow print debug log.
  final bool isDebug;

  /// Get value as stream.
  Stream<R> get stream => _streamController.stream;

  /// Convert the result received from the isolate before getting real result.
  /// This function useful when the result received from the isolate is different
  /// from the return type.
  final IsolateConverter<R>? converter;

  /// Convert the result received from the isolate before getting real result.
  /// This function useful when the result received from the isolate is different
  /// from the return type.
  ///
  /// This function only available in `Worker` mode on Web platform.
  final IsolateConverter<R>? workerConverter;

  /// Get current number of queues.
  int get queuesLength => queueStrategy.queuesCount;

  /// Strategy to control a new (incoming) computation.
  ///
  /// Basic strategies:
  ///   - [QueueStrategyUnlimited] - default.
  ///   - [QueueStrategyRemoveNewest]
  ///   - [QueueStrategyRemoveOldest]
  ///   - [QueueStrategyDiscardIncoming]
  final QueueStrategy<R, P> queueStrategy;

  /// If you want to call the [start] method manually without `await`, you can `await`
  /// later by using [ensureStarted] to ensure that all the isolates are started.
  Future<void> get ensureStarted => _startedCompleter.future;

  /// To check if the [start] method is completed or not.
  bool get isStarted => _startedCompleter.isCompleted;

  /// `Map<IsolateContactor instance, isBusy>`.
  final Map<IsolateContactor<R, P>, bool> _isolates =
      <IsolateContactor<R, P>, bool>{};

  /// Controller for stream.
  final StreamController<R> _streamController;
  late StreamSubscription<dynamic> _streamSubscription;

  /// Is the `start` method is starting.
  bool _isStarting = false;

  /// Control when the `start` method is completed.
  Completer<void> _startedCompleter = Completer();

  /// A default function for using the [IsolateManager.create] method.
  static void _defaultIsolateFunction<R, P>(dynamic params) {
    IsolateManagerFunction.customFunction<R, P>(
      params,
      onEvent: (controller, message) {
        final function = controller.initialParams;
        return (function as Function)(message) as FutureOr<R>;
      },
    );
  }

  /// Initialize the instance. This method can be called manually or will be
  /// called when the first `compute()` has been made.
  Future<void> start() async {
    // This instance is stoped.
    if (_streamController.isClosed) return;

    // Return here if this method is already completed.
    if (_startedCompleter.isCompleted) return;

    // If this method has already been called, it will wait for completion.
    if (_isStarting) return _startedCompleter.future;

    // Mark as the `start()` is starting.
    _isStarting = true;

    if (isCustomIsolate) {
      // Create the custom isolates.
      await Future.wait(
        <Future<void>>[
          for (int i = 0; i < concurrent; i++)
            IsolateContactor.createCustom<R, P>(
              isolateFunction as IsolateCustomFunction,
              workerName: workerName,
              initialParams: initialParams,
              converter: converter,
              workerConverter: workerConverter,
              debugMode: isDebug,
            ).then(
              (IsolateContactor<R, P> value) => _isolates
                  .addAll(<IsolateContactor<R, P>, bool>{value: false}),
            ),
        ],
      );
    } else {
      // Create isolates with the internal method.
      await Future.wait(
        <Future<void>>[
          for (int i = 0; i < concurrent; i++)
            IsolateContactor.createCustom<R, P>(
              _defaultIsolateFunction<R, P>,
              initialParams: isolateFunction as IsolateFunction<R, P>,
              workerName: workerName,
              converter: converter,
              workerConverter: workerConverter,
              debugMode: isDebug,
            ).then((value) => _isolates[value] = false),
        ],
      );
    }

    _streamSubscription = _streamController.stream.listen(
      (_) => _executeQueue(),
      onError: (_, __) => _executeQueue(),
    );

    _executeQueue();

    // Mark the `start()` to be completed.
    _startedCompleter.complete();
  }

  /// Stop isolate manager without close streamController.
  Future<void> _tempStop() async {
    _isStarting = false;
    _startedCompleter = Completer();
    queueStrategy.clear();
    await Future.wait(
      <Future<void>>[
        for (final isolate in _isolates.keys) isolate.dispose(),
        _streamSubscription.cancel(),
      ],
    );
    _isolates.clear();
  }

  /// Stop the isolate.
  Future<void> stop() async {
    await _tempStop();
    await _streamController.close();
  }

  /// Restart the isolate.
  Future<void> restart() async {
    await _tempStop();
    await start();
  }

  /// Compute isolate manager with [R] is return type.
  ///
  /// You can use [callback] to be able to receive many values before receiving
  /// the final result that is returned from the [call] method. The final
  /// result will be returned when the callback returns `true`. If you want a
  /// computation runs as soon as possible, you can set the [priority] to `true`
  /// to promote it to the top of the Queue.
  ///
  /// Ex:
  ///
  /// Without callback, the first value received from the Isolate is always the
  /// final value:
  ///
  /// ```dart
  /// final result = await isolate(params); // Get only the first result from the isolate
  /// ```
  ///
  /// With callback, only the `true` value is the final value, so all other values
  /// is marked as the progress values:
  ///
  /// ``` dart
  /// final result = await isolate.compute(params, (value) {
  ///       if (value is int) {
  ///         // Do something here with the value that will be not returned to the `result`.
  ///         print('progress: $value');
  ///         return false;
  ///       }
  ///
  ///       // The value is not `int` and will be returned to the `result` as the final result.
  ///       return true;
  ///  });
  /// ```
  Future<R> call(
    P params, {
    IsolateCallback<R>? callback,
    bool priority = false,
  }) =>
      compute(params, callback: callback, priority: priority);

  ///  Similar to the [compute], for who's using IsolateContactor.
  Future<R> sendMessage(
    P params, {
    IsolateCallback<R>? callback,
    bool priority = false,
  }) =>
      compute(params, callback: callback, priority: priority);

  /// Compute isolate manager with [R] is return type.
  ///
  /// You can use [callback] to be able to receive many values before receiving
  /// the final result that is returned from the [compute] method. The final
  /// result will be returned when the callback returns `true`. If you want a
  /// computation runs as soon as possible, you can set the [priority] to `true`
  /// to promote it to the top of the Queue.
  ///
  /// Ex:
  ///
  /// Without callback, the first value received from the Isolate is always the
  /// final value:
  ///
  /// ```dart
  /// final result = await isolate.compute(params); // Get only the first result from the isolate
  /// ```
  ///
  /// With callback, only the `true` value is the final value, so all other values
  /// is marked as the progress values:
  ///
  /// ``` dart
  /// final result = await isolate.compute(params, (value) {
  ///       if (value is int) {
  ///         // Do something here with the value that will be not returned to the `result`.
  ///         print('progress: $value');
  ///         return false;
  ///       }
  ///
  ///       // The value is not `int` and will be returned to the `result` as the final result.
  ///       return true;
  ///  });
  /// ```
  Future<R> compute(
    P params, {
    IsolateCallback<R>? callback,
    bool priority = false,
  }) async {
    await start();

    final queue = IsolateQueue<R, P>(params, callback);
    queueStrategy.add(queue, addToTop: priority);
    _executeQueue();

    return queue.completer.future;
  }

  /// Exccute the element in the queues.
  void _executeQueue() {
    printDebug(() => 'Number of queues: ${queueStrategy.queuesCount}');
    for (final isolate in _isolates.keys) {
      /// Allow calling `compute` before `start`.
      if (queueStrategy.hasNext() && _isolates[isolate] == false) {
        final queue = queueStrategy.getNext();
        _execute(isolate, queue);
      }
    }
  }

  /// Send and recieve value.
  Future<R> _execute(
    IsolateContactor<R, P> isolate,
    IsolateQueue<R, P> queue,
  ) async {
    // Mark the current isolate as busy.
    _isolates[isolate] = true;

    StreamSubscription<dynamic>? sub;
    sub = isolate.onMessage.listen(
      (event) async {
        if (await queue.callback(event)) {
          await sub?.cancel();

          // Send the result back to the main app.
          _streamController.sink.add(event);
          queue.completer.complete(event);

          // Mark the current isolate as free.
          _isolates[isolate] = false;
        }
      },
      onError: (Object error, StackTrace stackTrace) async {
        await sub?.cancel();

        // Send the exception back to the main app.
        _streamController.sink.addError(error, stackTrace);
        queue.completer.completeError(error, stackTrace);

        // Mark the current isolate as free.
        _isolates[isolate] = false;
      },
    );

    try {
      await isolate.sendMessage(queue.params);
    } catch (_, __) {
      /* Do not need to catch the Exception here because it's catched in the above Stream */
    }

    return queue.completer.future;
  }

  /// Print logs if [isDebug] is true
  void printDebug(Object? Function() object) {
    debugPrinter(object, debug: isDebug);
  }
}
