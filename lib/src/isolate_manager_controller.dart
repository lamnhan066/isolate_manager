import 'dart:async';

import 'package:isolate_manager/isolate_manager.dart';

import 'isolate_manager_controller/web.dart'
    if (dart.library.io) 'isolate_manager_controller/stub.dart';

/// This method only use to create a custom isolate.
///
/// The [params] is a default parameter of a custom isolate function.
/// `onDispose` will be called when the controller is disposed.
class IsolateManagerController<R, P> {
  final IsolateManagerControllerImpl<R, P> _delegate;

  /// This method only use to create a custom isolate.
  ///
  /// The [params] is a default parameter of a custom isolate function.
  /// `onDispose` will be called when the controller is disposed.
  IsolateManagerController(
    dynamic params, {
    void Function()? onDispose,
  }) : _delegate = IsolateManagerControllerImpl<R, P>(
          params,
          onDispose: onDispose,
        );

  /// Mark the isolate as initialized.
  ///
  /// This method is automatically applied when using `IsolateManagerFunction.customFunction`
  /// and `IsolateManagerFunction.workerFunction`.
  void initialized() => _delegate.initialized();

  /// Close this `IsolateManagerController`.
  Future<void> close() => _delegate.close();

  /// Get initial parameters when you create the IsolateManager.
  dynamic get initialParams => _delegate.initialParams;

  /// This parameter is only used for Isolate. Use to listen for values from the main application.
  Stream<P> get onIsolateMessage => _delegate.onIsolateMessage;

  /// Send values from Isolate to the main application (to `onMessage`).
  void sendResult(R result) => _delegate.sendResult(result);

  /// Send the `Exception` to the main app.
  void sendResultError(IsolateException exception) =>
      _delegate.sendResultError(exception);
}
