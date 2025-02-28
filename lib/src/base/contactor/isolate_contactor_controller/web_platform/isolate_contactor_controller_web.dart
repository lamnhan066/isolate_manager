import 'dart:async';

import 'package:isolate_manager/src/base/contactor/isolate_contactor_controller/isolate_contactor_controller_web.dart';
import 'package:isolate_manager/src/base/contactor/models/isolate_port.dart';
import 'package:isolate_manager/src/base/isolate_contactor.dart';

/// Implementation of the [IsolateContactorController] on `web` using `Future`.
class IsolateContactorControllerImplFuture<R, P>
    implements IsolateContactorControllerImpl<R, P> {
  /// Implementation of the [IsolateContactorController] in `web` with `Worker`.
  IsolateContactorControllerImplFuture(
    dynamic params, {
    required void Function()? onDispose,
    required R Function(dynamic)? converter,
  })  : _converter = converter,
        _onDispose = onDispose,
        _delegate = _extractController(params),
        _initialParams = params is List ? params.first : null {
    _delegateSubscription = _delegate.stream.listen(_handleEvent);
  }

  static StreamController<dynamic> _extractController(dynamic params) {
    if (params is List) {
      return (params.last as IsolateContactorControllerImpl).controller
          as StreamController<dynamic>;
    }
    return params as StreamController<dynamic>;
  }

  final StreamController<dynamic> _delegate;
  late final StreamSubscription<dynamic> _delegateSubscription;
  final StreamController<R> _mainStreamController =
      StreamController<R>.broadcast();
  final StreamController<P> _isolateStreamController =
      StreamController<P>.broadcast();

  final void Function()? _onDispose;
  final R Function(dynamic)? _converter;
  final dynamic _initialParams;

  @override
  Completer<void> ensureInitialized = Completer<void>();

  @override
  StreamController<dynamic> get controller => _delegate;

  @override
  dynamic get initialParams => _initialParams;

  @override
  Stream<R> get onMessage => _mainStreamController.stream;

  @override
  Stream<P> get onIsolateMessage => _isolateStreamController.stream;

  @override
  void initialized() {
    if (_delegate.isClosed) return;
    _delegate.sink.add({
      IsolatePort.main: IsolateState.initialized,
    });
  }

  @override
  void sendIsolate(P message) {
    if (_delegate.isClosed) return;
    _delegate.sink.add({
      IsolatePort.isolate: message,
    });
  }

  @override
  void sendIsolateState(IsolateState state) {
    if (_delegate.isClosed) return;
    _delegate.sink.add({
      IsolatePort.isolate: state,
    });
  }

  @override
  void sendResult(R message) {
    if (_delegate.isClosed) return;
    _delegate.sink.add({
      IsolatePort.main: message,
    });
  }

  @override
  void sendResultError(IsolateException exception) {
    if (_delegate.isClosed) return;
    _delegate.sink.add({
      IsolatePort.main: exception,
    });
  }

  @override
  Future<void> close() async {
    await Future.wait([
      _delegate.close(),
      _delegateSubscription.cancel(),
      _mainStreamController.close(),
      _isolateStreamController.close(),
    ]);
  }

  void _handleEvent(dynamic event) {
    if (event is! Map<IsolatePort, dynamic>) return;

    event.forEach((IsolatePort port, dynamic value) {
      switch (port) {
        case IsolatePort.main:
          _handleMainPort(value);
        case IsolatePort.isolate:
          _handleIsolatePort(value);
      }
    });
  }

  void _handleMainPort(dynamic value) {
    if (value is IsolateException) {
      _mainStreamController.addError(value.error, value.stack);
      return;
    }

    if (value == IsolateState.initialized) {
      if (!ensureInitialized.isCompleted) {
        ensureInitialized.complete();
      }
      return;
    }

    _mainStreamController.add(_converter?.call(value) ?? value as R);
  }

  void _handleIsolatePort(dynamic value) {
    if (value == IsolateState.dispose) {
      _onDispose?.call();
      unawaited(close());
      return;
    }

    if (!_isolateStreamController.isClosed) {
      _isolateStreamController.add(value as P);
    }
  }
}
