import 'dart:async';

import 'package:isolate_manager/src/base/src/models/isolate_port.dart';
import 'package:isolate_manager/src/base/src/models/isolate_state.dart';

import '../../isolate_contactor.dart';
import '../../models/exception.dart';
import '../isolate_contactor_controller_web.dart';

class IsolateContactorControllerImplFuture<R, P>
    implements IsolateContactorControllerImpl<R, P> {
  late StreamController _delegate;

  final StreamController<R> _mainStreamController =
      StreamController.broadcast();
  final StreamController<P> _isolateStreamController =
      StreamController.broadcast();

  final void Function()? onDispose;
  final IsolateConverter<R> converter;
  dynamic _initialParams;

  @override
  Completer<void> ensureInitialized = Completer();

  IsolateContactorControllerImplFuture(
    dynamic params, {
    required this.onDispose,
    required this.converter,
    required IsolateConverter<R> workerConverter,
  }) {
    if (params is List) {
      _delegate = params.last.controller as StreamController;
      _initialParams = params.first;
    } else {
      _delegate = params;
    }

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
  StreamController get controller => _delegate;

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
    try {
      _delegate.sink.add({IsolatePort.isolate: message});
    } catch (_) {
      // The delegate may be closed
    }
  }

  @override
  void sendIsolateState(IsolateState state) {
    try {
      _delegate.sink.add({IsolatePort.isolate: state});
    } catch (_) {
      // The delegate may be closed
    }
  }

  @override
  void sendResult(R message) {
    try {
      _delegate.sink.add({IsolatePort.main: message});
    } catch (_) {
      // The delegate may be closed
    }
  }

  @override
  void sendResultError(IsolateException exception) {
    try {
      _delegate.sink.add({IsolatePort.main: exception});
    } catch (_) {
      // The delegate may be closed
    }
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
