import 'dart:async';
import 'dart:js_interop';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:web/web.dart';

import '../base/isolate_contactor.dart';

/// This method only use to create a custom isolate.
///
/// The [params] is a default parameter of a custom isolate function.
/// `onDispose` will be called when the controller is disposed.
class IsolateManagerControllerImpl<R, P>
    implements IsolateManagerController<R, P> {
  /// Delegation of IsolateContactor.
  late IsolateContactorController<R, P> _delegate;

  /// This method only use to create a custom isolate.
  ///
  /// The [params] is a default parameter of a custom isolate function.
  /// `onDispose` will be called when the controller is disposed.
  IsolateManagerControllerImpl(
    dynamic params, {
    void Function()? onDispose,
  }) {
    if (params.runtimeType == DedicatedWorkerGlobalScope) {
      _delegate = _IsolateManagerWorkerController<R, P>(params);
    } else {
      _delegate = IsolateContactorController<R, P>(
        params,
        onDispose: onDispose,
      );
    }
  }

  /// Mark the isolate as initialized.
  ///
  /// This method is automatically applied when using `IsolateManagerFunction.customFunction`
  /// and `IsolateManagerFunction.workerFunction`.
  @override
  void initialized() => _delegate.initialized();

  /// Close this `IsolateManagerController`.
  @override
  Future<void> close() => _delegate.close();

  /// Get initial parameters when you create the IsolateManager.
  @override
  get initialParams => _delegate.initialParams;

  /// This parameter is only used for Isolate. Use to listen for values from the main application.
  @override
  Stream<P> get onIsolateMessage => _delegate.onIsolateMessage;

  /// Send values from Isolate to the main application (to `onMessage`).
  @override
  void sendResult(R result) => _delegate.sendResult(result);

  /// Send the `Exception` to the main app.
  @override
  void sendResultError(IsolateException exception) =>
      _delegate.sendResultError(exception);
}

class _IsolateManagerWorkerController<R, P>
    implements IsolateContactorController<R, P> {
  final DedicatedWorkerGlobalScope self;
  final _streamController = StreamController<P>.broadcast();

  _IsolateManagerWorkerController(this.self) {
    self.onmessage = (P event) {
      _streamController.sink.add(event);
    }.toJS;
  }

  @override
  Stream<P> get onIsolateMessage => _streamController.stream;

  @override
  get initialParams => null;

  /// Send result to the main app
  @override
  void sendResult(dynamic m) {
    self.postMessage(m);
  }

  /// Send error to the main app
  @override
  void sendResultError(IsolateException exception) {
    sendResult(exception.toJson());
  }

  /// Mark the Worker as initialized
  @override
  void initialized() {
    sendResult(IsolateState.initialized.toJson());
  }

  /// Close this `IsolateManagerWorkerController`.
  @override
  Future<void> close() async {
    self.close();
  }

  @override
  Completer<void> get ensureInitialized => throw UnimplementedError();

  @override
  Stream<R> get onMessage => throw UnimplementedError();

  @override
  void sendIsolate(P message) => throw UnimplementedError();

  @override
  void sendIsolateState(IsolateState state) => throw UnimplementedError();
}
