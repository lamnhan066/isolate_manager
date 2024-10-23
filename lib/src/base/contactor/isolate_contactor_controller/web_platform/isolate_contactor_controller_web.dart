import 'dart:async';

import 'package:isolate_manager/src/base/contactor/isolate_contactor_controller/isolate_contactor_controller_web.dart';
import 'package:isolate_manager/src/base/contactor/models/isolate_port.dart';
import 'package:isolate_manager/src/base/isolate_contactor.dart';

/// Implementation of the [IsolateContactorController] in `web` with `Future`.
class IsolateContactorControllerImplFuture<R, P>
    implements IsolateContactorControllerImpl<R, P> {
  /// Implementation of the [IsolateContactorController] in `web` with `Worker`.
  IsolateContactorControllerImplFuture(
    dynamic params, {
    required void Function()? onDispose,
    required R Function(dynamic) converter,
  })  : _converter = converter,
        _onDispose = onDispose,
        _delegate = params is List
            ? (params.last as IsolateContactorControllerImpl).controller
                as StreamController
            : params as StreamController,
        _initialParams = params is List ? params.first : null {
    _delegate.stream.listen((event) {
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

            _mainStreamController.add(_converter(value));
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
  final StreamController<dynamic> _delegate;

  final StreamController<R> _mainStreamController =
      StreamController.broadcast();
  final StreamController<P> _isolateStreamController =
      StreamController.broadcast();

  final void Function()? _onDispose;
  final IsolateConverter<R> _converter;
  final dynamic _initialParams;

  @override
  Completer<void> ensureInitialized = Completer();

  @override
  StreamController<dynamic> get controller => _delegate;

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
      _delegate.close(),
      _mainStreamController.close(),
      _isolateStreamController.close(),
    ]);
  }
}
