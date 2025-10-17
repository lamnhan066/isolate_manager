import 'dart:async';

import 'package:isolate_manager/src/base/contactor/isolate_contactor_controller/isolate_contactor_controller_web.dart'
    if (dart.library.io) 'isolate_contactor_controller/isolate_contactor_controller_stub.dart';
import 'package:isolate_manager/src/base/contactor/models/isolate_state.dart';
import 'package:isolate_manager/src/models/isolate_exceptions.dart';
import 'package:isolate_manager/src/utils/converter.dart';

/// Create controller for current `IsolateContactor`
abstract class IsolateContactorController<R, P> {
  /// Create controller for current `IsolateContactor`
  ///
  /// `params` is the default parameters of the isolate function.
  ///
  /// `onDispose` is called when the controller is disposed.
  factory IsolateContactorController(
    /// `params` is the default parameters of the isolate function.
    dynamic params, {

    /// `onDispose` is called when the controller is disposed.
    FutureOr<void> Function()? onDispose,
  }) {
    // This method is not used in this controller
    return IsolateContactorControllerImpl<R, P>(
      params,
      onDispose: onDispose,
      converter: converterHelper,
      workerConverter: converterHelper,
      debugMode: false,
    );
  }

  /// Mark as initialized.
  void initialized();

  /// Get initial params for `createCustom`
  dynamic get initialParams;

  /// Listen to result from the isolate
  Stream<R> get onMessage;

  /// Listen to the message is sent to isolate
  Stream<P> get onIsolateMessage;

  /// Ensure the `Isolate`/`Worker` has been initialized
  Completer<void> get ensureInitialized;

  /// Send `message` to the isolate for computation
  void sendIsolate(P message);

  /// Send an `IsolateState` message to the isolate
  void sendIsolateState(IsolateState state);

  /// Send the `result` of computation to `onIsolateMessage` stream
  void sendResult(R result);

  /// Send the `Exception` to the main app
  void sendResultError(IsolateException exception);

  /// Close this controller
  Future<void> close();
}
