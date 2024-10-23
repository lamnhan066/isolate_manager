import 'dart:async';
import 'dart:isolate';

import 'package:isolate_manager/src/base/contactor/isolate_contactor.dart';
import 'package:isolate_manager/src/base/contactor/isolate_contactor_controller.dart';
import 'package:isolate_manager/src/base/contactor/models/exception.dart';
import 'package:isolate_manager/src/base/contactor/models/isolate_port.dart';
import 'package:isolate_manager/src/base/contactor/models/isolate_state.dart';
import 'package:stream_channel/isolate_channel.dart';

/// Implementation of the [IsolateContactorController] in `io`.
class IsolateContactorControllerImpl<R, P>
    implements IsolateContactorController<R, P> {
  /// Implementation of the [IsolateContactorController] in `io`.
  IsolateContactorControllerImpl(
    dynamic params, {
    required void Function()? onDispose,
    required R Function(dynamic)? converter,
    // ignore: avoid_unused_constructor_parameters
    required R Function(dynamic)? workerConverter,
  })  : _converter = converter,
        _onDispose = onDispose,
        _delegate = params is List
            ? IsolateChannel.connectSend(params.last as SendPort)
            : IsolateChannel.connectReceive(params as ReceivePort),
        _initialParams = params is List ? params.first : null {
    _delegateSubscription = _delegate.stream.listen((event) {
      (event as Map<IsolatePort, dynamic>).forEach((IsolatePort key, value) {
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

            _mainStreamController.add(_converter?.call(value) ?? value as R);
          case IsolatePort.isolate:
            if (value == IsolateState.dispose) {
              _onDispose?.call();
              unawaited(close());
            } else {
              _isolateStreamController.add(value as P);
            }
        }
      });
    });
  }
  final IsolateChannel<dynamic> _delegate;
  late StreamSubscription<dynamic> _delegateSubscription;

  final StreamController<R> _mainStreamController =
      StreamController.broadcast();
  final StreamController<P> _isolateStreamController =
      StreamController.broadcast();
  final void Function()? _onDispose;
  final IsolateConverter<R>? _converter;
  final dynamic _initialParams;

  @override
  Completer<void> ensureInitialized = Completer();

  /// Get initial params for `createCustom`
  @override
  dynamic get initialParams => _initialParams;

  @override
  Stream<R> get onMessage => _mainStreamController.stream;

  @override
  Stream<P> get onIsolateMessage => _isolateStreamController.stream;

  @override
  void initialized() => _delegate.sink.add(
        <IsolatePort, IsolateState>{IsolatePort.main: IsolateState.initialized},
      );

  @override
  void sendIsolate(P message) {
    _delegate.sink.add(<IsolatePort, P>{IsolatePort.isolate: message});
  }

  @override
  void sendIsolateState(IsolateState state) {
    _delegate.sink.add(<IsolatePort, IsolateState>{IsolatePort.isolate: state});
  }

  @override
  void sendResult(R message) {
    _delegate.sink.add(<IsolatePort, R>{IsolatePort.main: message});
  }

  @override
  void sendResultError(IsolateException exception) {
    _delegate.sink
        .add(<IsolatePort, IsolateException>{IsolatePort.main: exception});
  }

  @override
  Future<void> close() async {
    await Future.wait(<Future<dynamic>>[
      _delegateSubscription.cancel(),
      _mainStreamController.close(),
      _isolateStreamController.close(),
    ]);
  }
}
