import 'package:isolate_contactor/isolate_contactor.dart';

class IsolateManagerController<R, P>
    implements IsolateContactorController<R, P> {
  /// Delegation of IsolateContactor
  late IsolateContactorController<R, P> _delegate;

  /// This method only use to create your own isolate.
  ///
  /// `params` is the params of the function.
  /// `onDispose` will be called when the controller is disposed.
  IsolateManagerController(
    dynamic params, {
    Function()? onDispose,
  }) {
    _delegate = IsolateContactorController(
      params,
      onDispose: onDispose,
    );
  }

  /// Close this `IsolateManagerController`
  @override
  Future<void> close() => _delegate.close();

  /// Get current controller for IsolateManager
  @override
  get controller => _delegate.controller;

  /// Get initial parameters when you create the IsolateManager
  @override
  get initialParams => _delegate.initialParams;

  /// This parameter is only used for Isolate. Use to listen for values from the main application.
  @override
  Stream<P> get onIsolateMessage => _delegate.onIsolateMessage;

  /// This parameter is only used by the main application. Use to listen for values from Isolate.
  @override
  Stream<R> get onMessage => _delegate.onMessage;

  /// Send values from the main app to Isolate for computation (to `onIsolateMessage`).
  @override
  void sendIsolate(P message) => _delegate.sendIsolate(message);

  /// Send a `Dispose` message to the isolate
  @override
  void sendIsolateState(Object state) => _delegate.sendIsolateState(state);

  /// Send values from Isolate to the main application (to `onMessage`).
  @override
  void sendResult(R result) => _delegate.sendResult(result);

  /// Send the `Exception` to the main app.
  @override
  void sendResultError(IsolateException exception) =>
      _delegate.sendResultError(exception);
}
