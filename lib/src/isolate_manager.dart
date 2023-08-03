import 'dart:async';
import 'dart:collection';

import 'package:isolate_contactor/isolate_contactor.dart';

import 'utils.dart';

typedef IsolateCallback<R> = FutureOr<bool> Function(R value);

class IsolateManager<R, P> {
  /// Debug logs prefix
  static String debugLogPrefix = 'Isolate Manager';

  /// Number of concurrent isolates
  final int concurrent;

  /// Isolate function
  final dynamic isolateFunction;

  /// Worker name
  final String workerName;

  /// Initial parameters
  final Object? initialParams;

  /// Is using your own isolate function
  final bool isOwnIsolate;

  /// Allow print debug log
  final bool isDebug;

  /// Similar to `stream`, for who's using IsolateContactor
  @Deprecated('Use [stream] instead')
  Stream<R> get onMessage => _streamController.stream;

  /// Get value as stream
  Stream<R> get stream => _streamController.stream;

  /// Convert the result received from the isolate before getting real result.
  /// This function useful when the result received from the isolate is different
  /// from the return type.
  final R Function(dynamic)? converter;

  /// Convert the result received from the isolate before getting real result.
  /// This function useful when the result received from the isolate is different
  /// from the return type.
  ///
  /// This function only available in `Worker` mode on Web platform.
  final R Function(dynamic)? workerConverter;

  IsolateManager._({
    required this.concurrent,
    required this.isolateFunction,
    required this.workerName,
    this.converter,
    this.workerConverter,
    this.initialParams,
    this.isOwnIsolate = false,
    this.isDebug = false,
  }) {
    // Set the debug log prefix
    IsolateContactor.debugLogPrefix = debugLogPrefix;
  }

  /// Easy way to create a new isolate.
  factory IsolateManager.create(
    /// A function that you want to create an isolate.
    FutureOr<R> Function(P params) isolateFunction, {
    /// Name of the .js file that you want to create a Worker.
    String workerName = '',

    /// Number of concurrent isolates for this function.
    int concurrent = 1,

    /// Convert values before you get the last result.
    ///
    /// This parameter isn't used for for `Worker` on Web, you can use `workerConverter`
    /// instead if you need to.
    R Function(dynamic)? converter,

    /// Convert values before you get the last result.
    ///
    /// This parameter is only used for `Worker` on Web, you can use `converter`
    /// instead if you need to.
    R Function(dynamic)? workerConverter,

    /// Print debug information.
    bool isDebug = false,
  }) =>
      IsolateManager._(
        concurrent: concurrent,
        isolateFunction: isolateFunction,
        workerName: workerName,
        converter: converter,
        workerConverter: workerConverter,
        isDebug: isDebug,
      );

  /// Create a new isolate with your own isolate function.
  factory IsolateManager.createOwnIsolate(
    /// A function that you want to create an isolate.
    void Function(dynamic) isolateFunction, {
    /// Name of the .js file that you want to create a Worker.
    String workerName = '',

    /// Initial parameters that you want to pass to your function.
    Object? initialParams,

    /// Number of isolates for this function.
    int concurrent = 1,

    /// Convert the result received from the isolate before getting real result.
    /// This function useful when the result received from the isolate is different
    /// from the return type.
    R Function(dynamic)? converter,

    /// Convert values before you get the last result.
    ///
    /// This parameter is only used for `Worker` on Web, you can use `converter`
    /// instead if you need to.
    R Function(dynamic)? workerConverter,

    /// Print debug information.
    bool isDebug = false,
  }) =>
      IsolateManager._(
        concurrent: concurrent,
        isolateFunction: isolateFunction,
        workerName: workerName,
        initialParams: initialParams,
        converter: converter,
        workerConverter: workerConverter,
        isOwnIsolate: true,
        isDebug: isDebug,
      );

  /// Queue of isolates
  final Queue<IsolateQueue<R, P>> _queues = Queue();

  /// Map<IsolateContactor instance, isBusy>
  final Map<IsolateContactor<R, P>, bool> _isolates = {};

  /// Controller for stream
  final StreamController<R> _streamController = StreamController.broadcast();
  StreamSubscription<R>? _streamSubscription;
  // final List<StreamSubscription<R>> _streamSubscriptions = [];

  /// Is the `start` method is starting
  bool _isStarting = false;

  /// Control when the `start` method is completed
  Completer<void> _startedCompleter = Completer();

  /// Initialize the instance. This method can be called manually or will be
  /// called when the first `compute()` has been made.
  Future<void> start() async {
    // This instance is stoped
    if (_streamController.isClosed) return;

    // Return here if this method is already completed
    if (_startedCompleter.isCompleted) return;

    // If this method has already been called, it will wait for completion
    if (_isStarting) return _startedCompleter.future;

    // Mark as the `start()` is starting
    _isStarting = true;

    if (isOwnIsolate) {
      // Create your own isolates
      await Future.wait(
        [
          for (int i = 0; i < concurrent; i++)
            IsolateContactor.createOwnIsolate<R, P>(
              isolateFunction as FutureOr<void> Function(dynamic),
              workerName: workerName,
              initialParams: initialParams,
              converter: converter,
              workerConverter: workerConverter,
              debugMode: isDebug,
            ).then((value) => _isolates.addAll({value: false}))
        ],
      );
    } else {
      // Create isolates with the internal method
      await Future.wait(
        [
          for (int i = 0; i < concurrent; i++)
            IsolateContactor.create<R, P>(
              isolateFunction as FutureOr<R> Function(P),
              workerName: workerName,
              converter: converter,
              workerConverter: workerConverter,
              debugMode: isDebug,
            ).then((value) => _isolates.addAll({value: false}))
        ],
      );
    }

    _streamSubscription = _streamController.stream.listen((result) {
      _excuteQueue();
    })
      // Needs to put onError here to make the try-catch work properly
      ..onError((error, stack) {});

    _excuteQueue();

    // Mark the `start()` to be completed
    _startedCompleter.complete();
  }

  /// Stop isolate manager without close streamController
  Future<void> _tempStop() async {
    _isStarting = false;
    _startedCompleter = Completer();
    _queues.clear();
    await Future.wait(
        [for (IsolateContactor isolate in _isolates.keys) isolate.dispose()]);
    _isolates.clear();
    _streamSubscription?.cancel();
  }

  /// Stop the isolate
  Future<void> stop() async {
    await _tempStop();
    await _streamController.close();
  }

  /// Restart the isolate
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
  /// ``` dart
  /// final result = await compute(params, (value) {
  ///       if (value is int) {
  ///         // Do something here with the value that is not returned to the `result`
  ///         print('progress: $value');
  ///         return false;
  ///       }
  ///       // Do something here with the final `result`
  ///       return true;
  ///   })
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
      /// Allow calling `compute` before `start`
      if (_queues.isNotEmpty && _isolates[isolate] == false) {
        final queue = _queues.removeFirst();
        _excute(isolate, queue);
      }
    }
  }

  /// Send and recieve value
  Future<R> _excute(IsolateContactor<R, P> isolate, IsolateQueue<R, P> queue) {
    if (queue.callback != null) {
      return _excuteWithCallback(isolate, queue);
    } else {
      return _excuteWithoutCallback(isolate, queue);
    }
  }

  Future<R> _excuteWithCallback(
      IsolateContactor<R, P> isolate, IsolateQueue<R, P> queue) async {
    // Mark the current isolate as busy
    _isolates[isolate] = true;

    StreamSubscription? sub;
    sub = isolate.onMessage.listen((event) async {
      // Callbacks on every event
      final completer = Completer<bool>();
      completer.complete(queue.callback!(event));
      if (await completer.future) {
        sub?.cancel();
        // Mark the current isolate as free
        _isolates[isolate] = false;
        // Send the result back to the main app
        _streamController.sink.add(event);
        queue.completer.complete(event);
      }
    }, onError: (error, stackTrace) {
      sub?.cancel();
      // Mark the current isolate as free
      _isolates[isolate] = false;

      // Send the exception back to the main app
      _streamController.sink.addError(error!, stackTrace);
      queue.completer.completeError(error, stackTrace);
    });
    isolate.sendMessage(queue.params);

    return queue.completer.future;
  }

  Future<R> _excuteWithoutCallback(
      IsolateContactor<R, P> isolate, IsolateQueue<R, P> queue) async {
    // Mark the current isolate as busy
    _isolates[isolate] = true;

    // Send the `param` to the isolate and wait for the result
    isolate.sendMessage(queue.params).then((value) {
      // Mark the current isolate as free
      _isolates[isolate] = false;

      // Send the result back to the main app
      _streamController.sink.add(value);
      queue.completer.complete(value);
    }).onError((error, stackTrace) {
      // Mark the current isolate as free
      _isolates[isolate] = false;

      // Send the exception back to the main app
      _streamController.sink.addError(error!, stackTrace);
      queue.completer.completeError(error, stackTrace);
    });

    return queue.completer.future;
  }

  /// Print debug log
  void _print(String log) {
    if (isDebug) print('[$debugLogPrefix] $log');
  }
}
