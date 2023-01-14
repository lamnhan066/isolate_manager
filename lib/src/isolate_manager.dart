import 'dart:async';
import 'dart:collection';

import 'package:isolate_contactor/isolate_contactor.dart';

import 'utils.dart';

class IsolateManager<R> {
  /// Number of concurrent isolates
  final int concurrent;

  /// Isolate function
  final dynamic Function(dynamic) isolateFunction;

  /// Worker name
  final String workerName;

  /// Initial parameters
  final dynamic initialParams;

  /// Is using your own isolate function
  final bool isOwnIsolate;

  /// Allow print debug log
  final bool isDebug;

  /// Similar to `stream`, for who's using IsolateContactor
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
  });

  /// Easy way to create a new isolate.
  factory IsolateManager.create(
    /// A function that you want to create an isolate.
    FutureOr<R> Function(dynamic) isolateFunction, {

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
    dynamic initialParams,

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
  final Queue<IsolateQueue<R>> _queue = Queue();

  /// Map<IsolateContactor instance, isBusy>
  final Map<IsolateContactor<R>, bool> _isolates = {};

  /// Controller for stream
  final StreamController<R> _streamController = StreamController.broadcast();
  final List<StreamSubscription<R>> _streamSubscriptions = [];

  /// Is the `start` method is starting
  bool _isStarting = false;

  /// Control when the `start` method is completed
  Completer<void> _startedCompleter = Completer();

  /// Initialize the instance. This method can be called manually or will be
  /// called when the first `compute()` has been made.
  Future<void> start() async {
    // If this method is already completed than return
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
            IsolateContactor.createOwnIsolate<R>(
              isolateFunction,
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
            IsolateContactor.create<R>(
              isolateFunction as FutureOr<R> Function(dynamic),
              workerName: workerName,
              converter: converter,
              workerConverter: workerConverter,
              debugMode: isDebug,
            ).then((value) => _isolates.addAll({value: false}))
        ],
      );
    }

    // _streamController = StreamController.broadcast();
    for (final isolate in _isolates.keys) {
      _streamSubscriptions.add(isolate.onMessage.listen((value) {
        _streamController.sink.add(value);
        if (_queue.isNotEmpty) {
          final queue = _queue.removeFirst();
          _excute(isolate, queue);
        }
      }));

      /// Allow calling `compute` before `start`
      if (_queue.isNotEmpty) {
        final queue = _queue.removeFirst();
        _excute(isolate, queue);
      }
    }

    // Mark the `start()` to be completed
    _startedCompleter.complete();
  }

  /// Stop isolate manager without close streamController
  Future<void> _tempStop() async {
    _isStarting = false;
    _startedCompleter = Completer();
    _queue.clear();
    await Future.wait(
        [for (final isolate in _isolates.keys) isolate.dispose()]);
    _isolates.clear();
    await Future.wait([for (final sub in _streamSubscriptions) sub.cancel()]);
    _streamSubscriptions.clear();
  }

  /// Stop isolate manager
  Future<void> stop() async {
    await Future.wait([
      _tempStop(),
      _streamController.close(),
    ]);
  }

  Future<void> restart() async {
    await _tempStop();
    await start();
  }

  ///  Similar to `commpute`, for who's using IsolateContactor
  Future<R> sendMessage(dynamic params) => compute(params);

  /// Compute isolate manager with [R] is return type.
  Future<R> compute(dynamic params) async {
    await start();

    final queue = IsolateQueue<R>(params);

    for (final isolate in _isolates.keys) {
      if (_isolates[isolate] == false) {
        return _excute(isolate, queue);
      }
    }

    _queue.add(queue);

    return queue.completer.future;
  }

  Future<R> _excute(IsolateContactor<R> isolate, IsolateQueue<R> queue) async {
    _isolates[isolate] = true;

    isolate.sendMessage(queue.params).then((value) {
      if (!queue.completer.isCompleted) queue.completer.complete(value);
      _isolates[isolate] = false;
    });

    return queue.completer.future;
  }
}
