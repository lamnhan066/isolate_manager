import 'dart:async';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager/src/base/shared/function.dart';
import 'package:path/path.dart';

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
    this.enableWasmConverter = true,
    bool isDebug = false,
  }) : _manager = IsolateManager.create(
          internalFunction,
          workerName: useWorker ? join(subPath, kSharedWorkerName) : '',
          workerConverter: workerConverter,
          concurrent: concurrent,
          queueStrategy: queueStrategy,
          enableWasmConverter: false,
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

  /// Flag to enable WebAssembly type conversion for numerical values.
  ///
  /// When an application is compiled to WebAssembly (WASM), JavaScript represents all
  /// numeric types as IEEE-754 doubles. This causes integer types (`int`, `List<int>`,
  /// `Iterable<int>`, etc.) to be automatically converted to `double` during serialization.
  ///
  /// When this flag is set to `true`, the isolate manager will automatically convert
  /// numeric values back to their intended types during message passing. This ensures
  /// type consistency between Dart and WASM/JavaScript environments.
  ///
  /// Default is `true`. Enable this when working with integer data in WASM environments.
  final bool enableWasmConverter;

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
    bool enableWasmConverter = true,
    bool priority = false,
  }) {
    return _execute(
      function,
      params,
      workerFunction: workerFunction,
      workerParams: workerParams,
      priority: priority,
      enableWasmConverter: enableWasmConverter,
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
    bool enableWasmConverter = true,
    bool priority = false,
  }) {
    return _execute(
      function,
      params,
      workerFunction: workerFunction,
      workerParams: workerParams,
      priority: priority,
      enableWasmConverter: enableWasmConverter,
    );
  }

  /// Execute the given [function] with its' [params].
  Future<R> _execute<R extends Object?, P extends Object?>(
    IsolateFunction<R, P> function,
    P params, {
    String? workerFunction,
    Object? workerParams,
    bool enableWasmConverter = true,
    bool priority = false,
  }) async {
    return platformExecute<R, P>(
      manager: _manager,
      function: function,
      params: params,
      workerFunction: workerFunction ??
          (workerMappings[function] == null
              ? null
              // We only need to get the basename of the worker function
              // because it may contain the subpath when using the generator and
              // the shared worker is only need the basename.
              : basename(workerMappings[function] ?? '')),
      workerParams: workerParams,
      priority: priority,
      enableWasmConverter: enableWasmConverter,
    );
  }

  /// Get the result as stream.
  Stream<Object?> get stream => _manager.stream;

  /// Starts all the isolates in the managed isolate pool.
  ///
  /// This method initializes the isolates if they haven't been started yet.
  /// While starting is optional (isolates start automatically when needed),
  /// calling this method explicitly ensures the isolates are ready
  /// before any computation is requested.
  ///
  /// Returns a [Future] that completes when all isolates have been started.
  Future<void> start() => _manager.start();

  /// Pauses the isolate manager, stopping all current operations without terminating the instance.
  ///
  /// This method:
  /// - Cancels all running isolate operations
  /// - Clears the task queue
  /// - Resets the internal state
  /// - Maintains the stream controller active
  ///
  /// Unlike [stop], this allows the manager to be restarted later with [start] or [restart]
  /// without creating a new instance.
  ///
  /// Throws [IsolateException] if the manager has already been stopped.
  Future<void> pause() => _manager.pause();

  /// Restarts the isolate manager by stopping and restarting all isolates.
  ///
  /// This method:
  /// 1. Pauses all running isolates
  /// 2. Clears the queue state
  /// 3. Creates new isolates with the original configuration
  ///
  /// This is useful when you need to:
  /// - Reset the isolate's internal state
  /// - Recover from error conditions
  /// - Apply new configuration changes
  ///
  /// Note: Any pending tasks in the queue will be lost during restart.
  /// Throws [IsolateException] if the manager is already stopped.
  Future<void> restart() => _manager.restart();

  /// Stops and completely terminates the isolate manager instance.
  ///
  /// This method:
  /// - Cancels all running isolate operations
  /// - Closes the stream controller, preventing any future operations
  /// - Releases all resources associated with this isolate manager
  ///
  /// After calling this method, the isolate manager cannot be restarted.
  ///
  /// This permanently releases all resources and closes the stream controller.
  /// If [start] or [restart] is called after stopping, an [IsolateException]
  /// will be thrown.
  ///
  /// To temporarily suspend operations with the ability to resume later,
  /// use [pause] instead.
  ///
  /// Returns a [Future] that completes when all resources have been released.
  Future<void> stop() => _manager.stop();
}
