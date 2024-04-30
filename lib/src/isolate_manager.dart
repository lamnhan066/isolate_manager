import 'dart:async';
import 'dart:collection';

import 'package:isolate_contactor/isolate_contactor.dart';

import 'utils.dart';

/// Type for the callback of the isolate.
typedef IsolateCallback<R> = FutureOr<bool> Function(R value);

/// Callback for the `createCustom`'s `function`.
typedef IsolateCustomFunction = IsolateFunction<void, dynamic>;

class IsolateManager<R, P> {
  /// Debug logs prefix.
  static String debugLogPrefix = 'Isolate Manager';

  /// Number of concurrent isolates.
  final int concurrent;

  /// Isolate function.
  final Object isolateFunction;

  /// Name of the `Worker` without the extension.
  ///
  /// Ex: Worker: `worker.js` => workerName: 'worker;
  ///     Worker: `workers/worker.js` => workerName: 'workers/worker'
  final String workerName;

  /// Initial parameters.
  final Object? initialParams;

  /// Is using your own isolate function.
  final bool isCustomIsolate;

  /// Mark an `Isolate` and `Worker` as initialized after spawned.
  ///
  /// TODO: Set this value to `false` by default in the next big release `v5.0.0`.
  ///
  /// An `Isolate` or a `Worker` need sometimes to be completely executed (ready
  /// to receive the messages from the main app). If this value is `true`,
  /// an `Isolate` or a `Worker` will be marked as initialized as soon as it's
  /// spawned, otherwise, the main app will wait for an `initialized` signal
  /// sent from the `Isolate` or `Worker` to ensure that it's completely executed and
  /// ready to receive the messages.
  ///
  /// If this value is set to `true`, we need to add a line to the custom function
  /// and worker to send a signal to the main app:
  ///
  ///   * Custom function:
  ///
  ///   ```dart
  ///   void customFunction(dynamic params) {
  ///     final controller = IsolateManagerController(params);
  ///     controller.onIsolateMessage.then((value){
  ///       // ...
  ///     });
  ///
  ///     controller.initialized(); // <--
  ///   }
  ///   ```
  ///
  ///   * Web worker:
  ///
  ///   ```dart
  ///   void main() {
  ///     callbackToStream('onmessage', (MessageEvent e) {
  ///       return js_util.getProperty(e, 'data');
  ///     }).listen((message) {
  ///       final Completer completer = Completer();
  ///       completer.future.then(
  ///         (value) => jsSendMessage(value),
  ///         onError: (err, stack) =>
  ///           jsSendMessage(IsolateException(err, stack).toJson()),
  ///       );
  ///       try {
  ///         completer.complete(function(message as P) as R);
  ///       } catch (err, stack) {
  ///         jsSendMessage(IsolateException(err, stack).toJson());
  ///       }
  ///     });
  ///
  ///     jsSendMessage(IsolateState.initialized.serialization); // <--
  ///   }
  ///   ```
  final bool autoInitialize;

  /// Allow print debug log.
  final bool isDebug;

  // coverage:ignore-start
  /// Similar to `stream`, for who's using IsolateContactor.
  @Deprecated('Use [stream] instead')
  Stream<R> get onMessage => _streamController.stream;
  // coverage:ignore-end

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
  int get queuesLength => _queues.length;

  /// If you want to call the [start] method manually without `await`, you can `await`
  /// later by using [ensureStarted] to ensure that all the isolates are started.
  Future<void> get ensureStarted => _startedCompleter.future;

  /// To check if the [start] method is completed or not.
  bool get isStarted => _startedCompleter.isCompleted;

  /// An easy way to create a new isolate.
  IsolateManager.create(
    IsolateFunction<R, P> this.isolateFunction, {
    this.workerName = '',
    this.concurrent = 1,
    this.converter,
    this.workerConverter,
    this.autoInitialize = true,
    this.isDebug = false,
  })  : isCustomIsolate = false,
        initialParams = '' {
    // Set the debug log prefix.
    IsolateContactor.debugLogPrefix = debugLogPrefix;
  }

  /// Create a new isolate with your own isolate function.
  IsolateManager.createCustom(
    IsolateCustomFunction this.isolateFunction, {
    this.workerName = '',
    this.initialParams,
    this.concurrent = 1,
    this.converter,
    this.workerConverter,
    this.autoInitialize = true,
    this.isDebug = false,
  }) : isCustomIsolate = true {
    // Set the debug log prefix.
    IsolateContactor.debugLogPrefix = debugLogPrefix;
  }

  // coverage:ignore-start
  /// Create a new isolate with your own isolate function.
  @Deprecated('Use `createCustom` instead')
  IsolateManager.createOwnIsolate(
    IsolateCustomFunction this.isolateFunction, {
    this.workerName = '',
    this.initialParams,
    this.concurrent = 1,
    this.converter,
    this.workerConverter,
    this.autoInitialize = true,
    this.isDebug = false,
  }) : isCustomIsolate = true {
    // Set the debug log prefix.
    IsolateContactor.debugLogPrefix = debugLogPrefix;
  }
  // coverage:ignore-end

  /// Queue of isolates.
  final Queue<IsolateQueue<R, P>> _queues = Queue();

  /// Map<IsolateContactor instance, isBusy>.
  final Map<IsolateContactor<R, P>, bool> _isolates = {};

  /// Controller for stream.
  final StreamController<R> _streamController = StreamController.broadcast();
  StreamSubscription<R>? _streamSubscription;
  // final List<StreamSubscription<R>> _streamSubscriptions = [];

  /// Is the `start` method is starting.
  bool _isStarting = false;

  /// Control when the `start` method is completed.
  Completer<void> _startedCompleter = Completer();

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
        [
          for (int i = 0; i < concurrent; i++)
            IsolateContactor.createCustom<R, P>(
              isolateFunction as IsolateCustomFunction,
              workerName: workerName,
              initialParams: initialParams,
              converter: converter,
              workerConverter: workerConverter,
              autoMarkAsInitialized: autoInitialize,
              debugMode: isDebug,
            ).then((value) => _isolates.addAll({value: false}))
        ],
      );
    } else {
      // Create isolates with the internal method.
      await Future.wait(
        [
          for (int i = 0; i < concurrent; i++)
            IsolateContactor.create<R, P>(
              isolateFunction as IsolateFunction<R, P>,
              workerName: workerName,
              converter: converter,
              workerConverter: workerConverter,
              autoMarkAsInitialized: autoInitialize,
              debugMode: isDebug,
            ).then((value) => _isolates.addAll({value: false}))
        ],
      );
    }

    _streamSubscription = _streamController.stream.listen((result) {
      _excuteQueue();
    })
      // Needs to put onError here to make the try-catch work properly.
      ..onError((error, stack) {});

    _excuteQueue();

    // Mark the `start()` to be completed.
    _startedCompleter.complete();
  }

  /// Stop isolate manager without close streamController.
  Future<void> _tempStop() async {
    _isStarting = false;
    _startedCompleter = Completer();
    _queues.clear();
    await Future.wait(
        [for (IsolateContactor isolate in _isolates.keys) isolate.dispose()]);
    _isolates.clear();
    _streamSubscription?.cancel();
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

  ///  Similar to the [compute], for who's using IsolateContactor.
  Future<R> sendMessage(P params, {IsolateCallback<R>? callback}) =>
      compute(params, callback: callback);

  /// Compute isolate manager with [R] is return type.
  ///
  /// You can use [callback] to be able to receive many values before receiving
  /// the final result that is returned from the [compute] method. The final
  /// result will be returned when the callback returns `true`.
  ///
  /// Ex:
  ///
  /// Without callback, the first value received from the Isolate is always the
  /// final value:
  ///
  /// ```dart
  /// final result = await isolate.compute(params); // Get only the first result from the isolate
  /// ```
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
  Future<R> compute(P params, {IsolateCallback<R>? callback}) async {
    await start();

    final queue = IsolateQueue<R, P>(params, callback);
    _queues.add(queue);

    _excuteQueue();

    return queue.completer.future;
  }

  /// Exccute the element in the queues.
  void _excuteQueue() {
    _print('Number of queues: ${_queues.length}');
    for (final isolate in _isolates.keys) {
      /// Allow calling `compute` before `start`.
      if (_queues.isNotEmpty && _isolates[isolate] == false) {
        final queue = _queues.removeFirst();
        _excute(isolate, queue);
      }
    }
  }

  /// Send and recieve value.
  Future<R> _excute(IsolateContactor<R, P> isolate, IsolateQueue<R, P> queue) {
    if (queue.callback != null) {
      return _excuteWithCallback(isolate, queue);
    } else {
      return _excuteWithoutCallback(isolate, queue);
    }
  }

  Future<R> _excuteWithCallback(
      IsolateContactor<R, P> isolate, IsolateQueue<R, P> queue) async {
    // Mark the current isolate as busy.
    _isolates[isolate] = true;

    StreamSubscription? sub;
    sub = isolate.onMessage.listen((event) async {
      // Callbacks on every event.
      final completer = Completer<bool>();
      completer.complete(queue.callback!(event));
      if (await completer.future) {
        sub?.cancel();
        // Mark the current isolate as free.
        _isolates[isolate] = false;
        // Send the result back to the main app.
        _streamController.sink.add(event);
        queue.completer.complete(event);
      }
    }, onError: (error, stackTrace) {
      sub?.cancel();
      // Mark the current isolate as free.
      _isolates[isolate] = false;

      // Send the exception back to the main app.
      _streamController.sink.addError(error!, stackTrace);
      queue.completer.completeError(error, stackTrace);
    });

    try {
      await isolate.sendMessage(queue.params);
    } catch (_, __) {
      /* Do not need to catch the Exception here because it's catched in the above Stream */
    }

    return queue.completer.future;
  }

  Future<R> _excuteWithoutCallback(
      IsolateContactor<R, P> isolate, IsolateQueue<R, P> queue) async {
    // Mark the current isolate as busy.
    _isolates[isolate] = true;

    // Send the `param` to the isolate and wait for the result.
    isolate.sendMessage(queue.params).then((value) {
      // Mark the current isolate as free.
      _isolates[isolate] = false;

      // Send the result back to the main app.
      _streamController.sink.add(value);
      queue.completer.complete(value);
    }).onError((error, stackTrace) {
      // Mark the current isolate as free.
      _isolates[isolate] = false;

      // Send the exception back to the main app.
      _streamController.sink.addError(error!, stackTrace);
      queue.completer.completeError(error, stackTrace);
    });

    return queue.completer.future;
  }

  /// Print a debug log.
  void _print(String log) {
    if (isDebug) print('[$debugLogPrefix] $log');
  }
}
