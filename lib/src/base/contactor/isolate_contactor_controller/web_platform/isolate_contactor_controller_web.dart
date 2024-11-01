import 'dart:async';

import 'package:isolate_manager/src/base/contactor/models/isolate_port.dart';
import 'package:isolate_manager/src/base/contactor/models/isolate_state.dart';

import '../../isolate_contactor.dart';
import '../../models/exception.dart';
import '../isolate_contactor_controller_web.dart';

class IsolateContactorControllerImplFuture<R, P>
    implements IsolateContactorControllerImpl<R, P> {
  final StreamController<dynamic> _delegate;

  final StreamController<R> _mainStreamController =
      StreamController.broadcast();
  final StreamController<P> _isolateStreamController =
      StreamController.broadcast();

  final void Function()? onDispose;
  final IsolateConverter<R> converter;
  final dynamic _initialParams;

  @override
  Completer<void> ensureInitialized = Completer();

  IsolateContactorControllerImplFuture(
    dynamic params, {
    required this.onDispose,
    required this.converter,
    required IsolateConverter<R> workerConverter,
  })  : _delegate = params is List
            ? params.last.controller as StreamController
            : params,
        _initialParams = params is List ? params.first : null {
    _delegate.stream.listen((event) {
      (event as Map<IsolatePort, dynamic>).forEach((key, value) {
        switch (key) {
          case IsolatePort.main:
            if (value is IsolateException) {
              _mainStreamController.addError(value.error, value.stack);
              break;
            }

            if (value == IsolateState.initialized) {
              if (!ensureInitialized.isCompleted) {
                ensureInitialized.complete();
              }
              break;
            }

            _mainStreamController.add(converter(value));
            break;
          case IsolatePort.isolate:
            if (value == IsolateState.dispose) {
              if (onDispose != null) onDispose!();
              close();
            } else {
              _isolateStreamController.add(value);
            }
            break;
        }
      });
    });
  }

  /// Get this StreamController
  @override
  StreamController<dynamic> get controller => _delegate;

  /// Get initial params for `createCustom`
  @override
  dynamic get initialParams => _initialParams;

  @override
  Stream<R> get onMessage => _mainStreamController.stream;

  @override
  Stream<P> get onIsolateMessage => _isolateStreamController.stream;

  @override
  void initialized() =>
      _delegate.sink.add({IsolatePort.main: IsolateState.initialized});

  @override
  void sendIsolate(P message) {
    _delegate.sink.add({IsolatePort.isolate: message});
  }

  @override
  void sendIsolateState(IsolateState state) {
    _delegate.sink.add({IsolatePort.isolate: state});
  }

  @override
  void sendResult(R message) {
    _delegate.sink.add({IsolatePort.main: message});
  }

  @override
  void sendResultError(IsolateException exception) {
    _delegate.sink.add({IsolatePort.main: exception});
  }

  @override
  Future<void> close() async {
    await Future.wait([
      _delegate.close(),
      _mainStreamController.close(),
      _isolateStreamController.close(),
    ]);
  }
}
