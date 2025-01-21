import 'dart:async';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager/src/base/shared/function.dart';

/// Default shared worker name.
const String kSharedWorkerName = r'$shared_worker';

/// Create multiple long live isolates for computation. This method can be used
/// to compute multiple functions.
class IsolateManagerShared {
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
  IsolateManagerShared({
    int concurrent = 1,
    bool useWorker = false,
    Object? Function(dynamic)? workerConverter,
    this.workerMappings = const <Function, String>{},
    bool autoStart = true,
    String subPath = '',
    QueueStrategy<Object, List<Object>>? queueStrategy,
    bool isDebug = false,
  }) : _manager = IsolateManager.create(
          internalFunction,
          workerName: useWorker ? '$subPath/$kSharedWorkerName' : '',
          workerConverter: workerConverter,
          concurrent: concurrent,
          queueStrategy: queueStrategy,
          isDebug: isDebug,
        ) {
    if (autoStart) start();
  }

  /// The instance of the [IsolateManager].
  final IsolateManager<Object?, List<dynamic>> _manager;

  /// Predefine the mapping between a function and a name of worker function,
  /// so we can ignore the `workerName` parameter when we compute a function
  /// multiple times.
  final Map<Function, String> workerMappings;

  /// Check that the [IsolateManager] is started or not.
  bool get isStarted => _manager.isStarted;

  /// Ensure that the [IsolateManagerShared] was already started.
  Future<void> get ensureStarted => _manager.ensureStarted;

  /// Compute the given [function] with given [params].
  ///
  /// The [workerFunction] is the name of the function that have created in `worker.dart`.
  /// You can ignore this parameter when the [workerMappings] is specified.
  ///
  /// [workerParams] is specific params for `Worker`, [params] will be use if this value is null.
  ///
  /// Equavient of [compute].
  Future<R> call<R extends Object?, P extends Object?>(
    IsolateFunction<R, P> function,
    P params, {
    String? workerFunction,
    Object? workerParams,
    bool priority = false,
  }) {
    return _excute(
      function,
      params,
      workerFunction: workerFunction,
      workerParams: workerParams,
      priority: priority,
    );
  }

  /// Compute the given [function] with given [params].
  ///
  /// [workerFunction] is the name of the function that have created in `worker.dart`.
  /// You can ignore this parameter when the [workerMappings] is specified.
  ///
  /// [workerParams] is specific params for `Worker`, [params] will be use if this value is null.
  Future<R> compute<R extends Object?, P extends Object?>(
    IsolateFunction<R, P> function,
    P params, {
    String? workerFunction,
    Object? workerParams,
    bool priority = false,
  }) {
    return _excute(
      function,
      params,
      workerFunction: workerFunction,
      workerParams: workerParams,
      priority: priority,
    );
  }

  /// Execute the given [function] with its' [params].
  Future<R> _excute<R extends Object?, P extends Object?>(
    IsolateFunction<R, P> function,
    P params, {
    String? workerFunction,
    Object? workerParams,
    bool priority = false,
  }) async {
    return platformExecute<R, P>(
      manager: _manager,
      function: function,
      params: params,
      workerFunction: workerFunction ?? workerMappings[function],
      workerParams: workerParams,
      priority: priority,
    );
  }

  /// Get the result as stream.
  Stream<Object?> get stream => _manager.stream;

  /// Start all the isolates. This method is optional because it will be started
  /// automatically when it needs to calculate.
  Future<void> start() => _manager.start();

  /// Restart all the isolates.
  Future<void> restart() => _manager.restart();

  /// Stop all the isolates.
  Future<void> stop() => _manager.stop();
}
