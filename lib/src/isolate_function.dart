import 'dart:async';

import 'package:isolate_manager/isolate_manager.dart';

import 'isolate_worker/isolate_worker_web.dart'
    if (dart.library.io) 'isolate_worker/isolate_worker_stub.dart';

/// A callback for the [isolateCustomFunction] that will be executed only one time
/// before all events.
typedef IsolateOnInitialCallback<T> = void Function(
    IsolateManagerController controller, T initialParams);

/// A callback for the [isolateCustomFunction] that will be executed only one time
/// before all events.
typedef IsolateOnDisposeCallback<T> = void Function(
    IsolateManagerController controller);

/// A callback for the [isolateCustomFunction] that will be executed every time
/// the [message] is received from the `sendMessage` or `execute` method.
typedef IsolateOnEventCallback<R, P> = FutureOr<R> Function(
    IsolateManagerController controller, P message);

class IsolateFunction {
  /// Create a custom isolate function.
  ///
  /// The [onInitial] and [onDispose] will be executed only one time in the beginning
  /// and at the end. The [onEvent] will be executed every time the `message` is received
  /// from the main isolate. You can set the [autoHandleException] to `false` if
  /// you want to `controller.sendResultError` by yourself, and set the [autoHandleResult]
  /// if you want to `controller.sendResult` yourself. By defaults, when the [onEvent]
  /// was executed, the result will be sent to the main isolate and the `Exception`
  /// will also be sent.
  ///
  /// ```dart
  /// void customIsolateFunction(dynamic params) {
  ///   isolateCustomFunction(
  ///     params,
  ///     onEvent: (controller, message) => fetchAndDecode(message),
  ///     onInitial: (controller, initialParams) {
  ///       /* This event will be executed before all the other events and should not be a `Future` event */
  ///     }
  ///     onDispose: (controller) {
  ///       /* This event will be executed after all the other events and should not be a `Future` event */
  ///     }
  ///   );
  /// }
  /// ```
  static customFunction<R, P>(
    dynamic params, {
    required IsolateOnEventCallback<R, P> onEvent,
    IsolateOnInitialCallback? onInitial,
    IsolateOnDisposeCallback? onDispose,
    bool autoHandleException = true,
    bool autoHandleResult = true,
  }) {
    // Initialize the controller for the child isolate. This function will be declared
    // with `Map<String, dynamic>` as the return type (.sendResult) and `String` as the parameter type (.sendMessage).
    late IsolateManagerController controller;
    controller = IsolateManagerController(
      params,
      onDispose: onDispose == null
          ? null
          : () {
              onDispose(controller);
              controller.close();
            },
    );

    // Get your initialParams.
    // Notice that these `initialParams` are different from the `params` above.
    onInitial?.call(controller, controller.initialParams);

    // Do your one-time stuff here; this code will be called only once when you `start`
    // this instance of `IsolateManager`.

    // Listen to messages received from the main isolate; this code will be called each time
    // you use `compute` or `sendMessage`.
    controller.onIsolateMessage.listen((message) {
      // Create a completer
      Completer completer = Completer();

      // Handle the result and exceptions
      completer.future.then(
        (value) => autoHandleResult ? controller.sendResult(value) : null,
        // Send the exception to your main app
        onError: autoHandleException
            ? (err, stack) =>
                controller.sendResultError(IsolateException(err, stack))
            : null,
      );

      // Use try-catch to send the exception to the main app
      try {
        completer.complete(onEvent(controller, message));
      } catch (err, stack) {
        // Send the exception to your main app
        if (autoHandleException) {
          completer.completeError(err, stack);
        } else {
          rethrow;
        }
      }
    });
  }

  /// Create a worker in your `main`.
  ///
  /// ```dart
  /// main() {
  ///   isolateWorker(myFunction);
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
  static void workerFunction<R, P>(IsolateWorkerFunction<R, P> function) {
    return isolateWorkerImpl<R, P>(function);
  }
}
