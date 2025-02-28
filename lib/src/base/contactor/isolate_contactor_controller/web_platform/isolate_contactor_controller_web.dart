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
        _initialParams = params is List ? params.first : null,
        _mainStreamController = StreamController<R>.broadcast(sync: true),
        _isolateStreamController = StreamController<P>.broadcast(sync: true) {
    _streamSubscription = _delegate.stream.listen(_handleEvent);
  }

  static StreamController<dynamic> _extractController(dynamic params) {
    if (params is List) {
      return (params.last as IsolateContactorControllerImpl).controller
          as StreamController<dynamic>;
    }
    return params as StreamController<dynamic>;
  }

  final StreamController<dynamic> _delegate;
  final StreamController<R> _mainStreamController;
  final StreamController<P> _isolateStreamController;
  final void Function()? _onDispose;
  final R Function(dynamic)? _converter;
  final dynamic _initialParams;
  late final StreamSubscription<dynamic> _streamSubscription;

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
      _mainStreamController.close(),
      _isolateStreamController.close(),
      _streamSubscription.cancel(),
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
    switch (value) {
      case final R r:
        try {
          _mainStreamController.add(_converter?.call(r) ?? r);
        } catch (e, stack) {
          _mainStreamController.addError(e, stack);
        }
      case == IsolateState.initialized:
        if (!ensureInitialized.isCompleted) {
          ensureInitialized.complete();
        }
      case final IsolateException e:
        _mainStreamController.addError(e.error, e.stack);
      default:
        _mainStreamController.addError(
          IsolateException('Unhandled $value from the Isolate'),
        );
    }
  }

  void _handleIsolatePort(dynamic value) {
    switch (value) {
      case P _:
        try {
          _isolateStreamController.add(value);
        } catch (e, stack) {
          _isolateStreamController.addError(e, stack);
        }
      case == IsolateState.dispose:
        _onDispose?.call();
        unawaited(close());
      default:
        _isolateStreamController.addError(
          IsolateException('Unhandled $value from the App'),
        );
    }
  }
}
