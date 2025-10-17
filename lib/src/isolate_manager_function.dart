import 'dart:async';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager/src/base/shared/function.dart';
import 'package:isolate_manager/src/isolate_worker/isolate_worker_web.dart'
    if (dart.library.io) 'isolate_worker/isolate_worker_stub.dart';

/// A callback for the [IsolateManagerFunction.customFunction] that will be executed only one time
/// before all events.
typedef IsolateOnInitCallback<R, P> =
    FutureOr<void> Function(IsolateManagerController<R, P> controller);

/// A callback for the [IsolateManagerFunction.customFunction] that will be executed only one time
/// before all events.
typedef IsolateOnDisposeCallback<R, P> =
    void Function(IsolateManagerController<R, P> controller);

/// A callback for the [IsolateManagerFunction.customFunction] that will be executed every time
/// the [message] is received from the `sendMessage` or `execute` method.
typedef IsolateOnEventCallback<R, P> =
    FutureOr<R> Function(IsolateManagerController<R, P> controller, P message);

/// A function for the `IsolateManagerFunction.workerFunction`.
typedef IsolateWorkerFunction<R, P> = FutureOr<R> Function(P message);

/// The helper functions for the [IsolateManager].
abstract class IsolateManagerFunction {
  /// Create a custom isolate function.
  ///
  /// The [onInit] and [onDispose] will be executed only one time in the beginning
  /// and at the end. The [onEvent] will be executed every time the `message` is received
  /// from the main isolate, the return type should be specified to avoid
  /// the `NULL` return type. You can set the [autoHandleException] to `false` if
  /// you want to `controller.sendResultError` by yourself, and set the [autoHandleResult]
  /// if you want to `controller.sendResult` yourself. By defaults, when the [onEvent]
  /// was executed, the result will be sent to the main isolate and the `Exception`
  /// will also be sent.
  ///
  /// ```dart
  /// void customIsolateFunction(dynamic params) {
  ///   IsolateManagerFunction.customFunction<int, int>(
  ///     params,
  ///     onInit: (controller) {
  ///        // This event will be executed before all the other events.
  ///        //
  ///        // This event can be a `Future` function.
  ///     },
  ///     onEvent: (controller, message) {
  ///       /* This event will be executed every time the `message` is received from the main isolate */
  ///       return fetchAndDecode(message);
  ///     },
  ///     onDispose: (controller) {
  ///        /* This event will be executed after all the other events and should NOT be a `Future` event */
  ///     },
  ///   );
  /// }
  /// ```
  static Future<void> customFunction<R, P>(
    /// A default parameter that used by the package.
    dynamic params, {
    required IsolateOnEventCallback<R, P> onEvent,
    IsolateOnInitCallback<R, P>? onInit,
    IsolateOnDisposeCallback<R, P>? onDispose,
    bool autoHandleException = true,
    bool autoHandleResult = true,
  }) async {
    // Initialize the controller for the child isolate. This function will be declared
    // with `Map<String, dynamic>` as the return type (.sendResult) and `String` as the parameter type (.sendMessage).
    late IsolateManagerController<R, P> controller;
    StreamSubscription<P>? subscription;

    controller = IsolateManagerController(
      params,
      onDispose:
          onDispose == null
              ? null
              : () async {
                onDispose(controller);
                await subscription?.cancel();
                await controller.close();
              },
    );

    await onInit?.call(controller);

    // Listen to messages received from the main isolate; this code will be called each time
    // you use `compute` or `sendMessage`.
    subscription = controller.onIsolateMessage.listen((message) async {
      // Use try-catch to send the exception to the main app
      try {
        final value = await onEvent(controller, message);
        if (autoHandleResult) {
          controller.sendResult(value);
        }
      } catch (err, stack) {
        // Send the exception to your main app
        if (autoHandleException) {
          controller.sendResultError(IsolateException(err, stack));
        } else {
          rethrow;
        }
      }
    });

    controller.initialized();
  }

  // TODO(lamnhan066): Find a way to test these methods because it only used by the compiled JS Worker.
  // coverage:ignore-start
  // Tested by compiling to `js` for the Web Worker.
  //
  /// Create a worker in your `main`.
  ///
  /// ```dart
  /// import 'package:isolate_manager/isolate_manager.dart';

  /// main() {
  ///   // The function `fetchAndDecode` MUST NOT depend on any Flutter library
  ///   IsolateManagerFunction.workerFunction(
  ///     fetchAndDecode,
  ///     onInit: (controller) {
  ///       // This is optional.
  ///     }
  ///   );
  /// }
  /// ```
  ///
  /// Build it with `dart compile js worker.dart -o worker.js -O4` and copy the `worker.js` to
  /// your Web folder.
  ///
  /// When you're using the [onInit], you have to set the `autoInitialize` parameter
  /// of the `create` and `createCustom` to `false`. Without it, the `Worker` will
  /// be stucked forever.
  ///
  /// If you need to throw an exception, you should only throw the `message`
  /// instead of a whole Object because it may not be shown as expected when
  /// sending back to the main app.
  ///
  /// ``` dart
  ///  return throw 'This is an error that you need to catch in your main app';
  /// ```
  static Future<void> workerFunction<R, P>(
    IsolateWorkerFunction<R, P> function, {
    IsolateOnInitCallback<R, P>? onInit,
  }) {
    return isolateWorkerImpl<R, P>(function, onInit);
  }

  /// Create a custom Worker function.
  ///
  ///
  /// ```dart
  /// void main() {
  ///   IsolateManagerFunction.customWorkerFunction(customFunction);
  /// }
  ///
  /// void customFunction(dynamic params) {
  ///   IsolateManagerFunction.customFunction<int, int>(
  ///     onInit: (controller) {
  ///        // This event will be executed before all the other events.
  ///        //
  ///        // This event can be a `Future` function.
  ///     },
  ///     onEvent: (controller, message) {
  ///       /* This event will be executed every time the `message` is received from the main isolate */
  ///       return fetchAndDecode(message);
  ///     },
  ///     onDispose: (controller) {
  ///        /* This event will be executed after all the other events and should NOT be a `Future` event */
  ///     },
  ///   );
  /// }
  /// ```
  /// Build it with `dart compile js worker.dart -o worker.js -O4` and copy the `worker.js` to
  /// your Web folder.
  static void customWorkerFunction(
    IsolateWorkerFunction<void, dynamic> function,
  ) {
    return customWorkerFunctionImpl(function);
  }

  /// Create a worker in your `main`.
  ///
  /// ```dart
  /// main() {
  ///   /* Mapping between your function as String and real `Function`.
  ///   This function MUST NOT depends on any Flutter library. */
  ///   IsolateManagerFunction.sharedWorkerFunction({
  ///     'add' : add,
  ///   });
  /// }
  /// ```
  ///
  /// Build it with `dart compile js worker.dart -o worker.js -O4` and copy the `worker.js` to
  /// your Web folder.
  ///
  /// If you need to throw an exception, you should only throw the `message`
  /// instead of a whole Object because it may not be shown as expected when
  /// sending back to the main app.
  ///
  /// ``` dart
  ///  return throw 'This is an error that you need to catch in your main app';
  /// ```
  static void sharedWorkerFunction(Map<String, Function> map) {
    return sharedWorkerFunctionImpl(map);
  }

  // coverage:ignore-end
}
