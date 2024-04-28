import 'package:isolate_contactor/isolate_contactor.dart';

class IsolateManagerController<R, P> {
  /// Delegation of IsolateContactor.
  late IsolateContactorController<R, P> _delegate;

  /// This method only use to create your own isolate.
  ///
  /// `params` is the params of the function.
  /// `onDispose` will be called when the controller is disposed.
  IsolateManagerController(
    dynamic params, {
    void Function()? onDispose,
  }) {
    _delegate = IsolateContactorController<R, P>(
      params,
      onDispose: onDispose,
    );
  }

  /// Close this `IsolateManagerController`.
  Future<void> close() => _delegate.close();

  /// Get initial parameters when you create the IsolateManager.
  get initialParams => _delegate.initialParams;

  /// This parameter is only used for Isolate. Use to listen for values from the main application.
  Stream<P> get onIsolateMessage => _delegate.onIsolateMessage;

  /// Send values from Isolate to the main application (to `onMessage`).
  void sendResult(R result) => _delegate.sendResult(result);

  /// Send the `Exception` to the main app.
  void sendResultError(IsolateException exception) =>
      _delegate.sendResultError(exception);
}
