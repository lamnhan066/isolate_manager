import 'dart:async';
import 'dart:js_interop';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager/src/base/isolate_contactor.dart';
import 'package:isolate_manager/src/utils/check_subtype.dart';
import 'package:web/web.dart';

/// This method only use to create a custom isolate.
class IsolateManagerControllerImpl<R, P>
    implements IsolateManagerController<R, P> {
  /// This method only use to create a custom isolate.
  ///
  /// The [params] is a default parameter of a custom isolate function.
  /// `onDispose` will be called when the controller is disposed.
  IsolateManagerControllerImpl(
    dynamic params, {
    void Function()? onDispose,
  }) : _delegate = params.runtimeType == DedicatedWorkerGlobalScope
            ? _IsolateManagerWorkerController<R, P>(
                params as DedicatedWorkerGlobalScope,
                onDispose: onDispose,
              )
            : IsolateContactorController<R, P>(params, onDispose: onDispose);

  /// Delegation of IsolateContactor.
  final IsolateContactorController<R, P> _delegate;

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
  dynamic get initialParams => _delegate.initialParams;

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

// TODO(lamnhan066): Find a way to test these methods because it only used by the compiled JS Worker.
// coverage:ignore-start
class _IsolateManagerWorkerController<R, P>
    implements IsolateContactorController<R, P> {
  _IsolateManagerWorkerController(this.self, {this.onDispose}) {
    self.onmessage = (MessageEvent event) {
      dynamic result = event.data.dartify();
      if (isIsolateTypeSubtype<P>()) {
        result = ImType.wrap(result as Object);
      }
      _streamController.sink.add(result as P);
    }.toJS;
  }
  final DedicatedWorkerGlobalScope self;
  final void Function()? onDispose;
  final _streamController = StreamController<P>.broadcast();

  @override
  Stream<P> get onIsolateMessage => _streamController.stream.cast();

  @override
  Object? get initialParams => null;

  /// Send result to the main app
  @override
  void sendResult(R m) {
    if (m is ImType) {
      self.postMessage(
        <String, Object?>{'type': 'data', 'value': m.unwrap}.jsify(),
      );
    } else {
      self.postMessage(<String, Object?>{'type': 'data', 'value': m}.jsify());
    }
  }

  /// Send error to the main app
  @override
  void sendResultError(IsolateException exception) {
    self.postMessage(exception.toMap().jsify());
  }

  /// Mark the Worker as initialized
  @override
  void initialized() {
    self.postMessage(IsolateState.initialized.toMap().jsify());
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
  void sendIsolate(dynamic message) => throw UnimplementedError();

  @override
  void sendIsolateState(IsolateState state) => throw UnimplementedError();
}
// coverage:ignore-end
