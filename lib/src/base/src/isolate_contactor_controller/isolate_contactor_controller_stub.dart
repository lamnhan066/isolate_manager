import 'dart:async';

import 'package:isolate_manager/src/base/src/models/isolate_port.dart';
import 'package:isolate_manager/src/base/src/models/isolate_state.dart';
import 'package:stream_channel/isolate_channel.dart';

import '../isolate_contactor.dart';
import '../isolate_contactor_controller.dart';
import '../models/exception.dart';

class IsolateContactorControllerImpl<R, P>
    implements IsolateContactorController<R, P> {
  late IsolateChannel _delegate;
  late StreamSubscription _delegateSubscription;

  final StreamController<R> _mainStreamController =
      StreamController.broadcast();
  final StreamController<P> _isolateStreamController =
      StreamController.broadcast();
  final void Function()? onDispose;
  final IsolateConverter<R>? converter;
  dynamic _initialParams;

  @override
  Completer<void> ensureInitialized = Completer();

  IsolateContactorControllerImpl(
    dynamic params, {
    required this.onDispose,
    required this.converter, // Converter for native
    required IsolateConverter<R>?
        workerConverter, // Converter for Worker (Web Only)
  }) {
    if (params is List) {
      _delegate = IsolateChannel.connectSend(params.last);
      _initialParams = params.first;
    } else {
      _delegate = IsolateChannel.connectReceive(params);
    }

    _delegateSubscription = _delegate.stream.listen((event) {
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

            _mainStreamController
                .add(converter == null ? value : converter!(value));
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
      _delegateSubscription.cancel(),
      _mainStreamController.close(),
      _isolateStreamController.close(),
    ]);
  }
}
