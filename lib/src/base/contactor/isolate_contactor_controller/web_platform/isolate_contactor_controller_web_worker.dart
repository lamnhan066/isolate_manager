import 'dart:async';
import 'dart:js_interop';

import 'package:isolate_manager/src/base/contactor/isolate_contactor_controller/isolate_contactor_controller_web.dart';
import 'package:isolate_manager/src/base/contactor/utils/utils.dart';
import 'package:isolate_manager/src/base/isolate_contactor.dart';
import 'package:web/web.dart';

/// Implementation of the [IsolateContactorController] in `web` with `Worker`.
class IsolateContactorControllerImplWorker<R, P>
    implements IsolateContactorControllerImpl<R, P> {
  /// Implementation of the [IsolateContactorController] in `web` with `Worker`.
  IsolateContactorControllerImplWorker(
    dynamic params, {
    required void Function()? onDispose, // Converter for native
    required R Function(dynamic)
        workerConverter, // Converter for Worker (Web Only)
  })  : _workerConverter = workerConverter,
        _onDispose = onDispose,
        _delegate = params is List
            ? (params.last as IsolateContactorControllerImpl).controller
                as Worker
            : params as Worker,
        _initialParams = params is List ? params.first : null {
    _delegate.onmessage = (MessageEvent event) {
      final data = dartify(event.data)! as Map;

      if (data['type'] == 'data') {
        _mainStreamController.add(_workerConverter(data['value']));
        return;
      }

      if (IsolateState.initialized.isValidMap(data)) {
        if (!ensureInitialized.isCompleted) {
          ensureInitialized.complete();
        }
        return;
      }

      if (IsolateState.dispose.isValidMap(data)) {
        _onDispose!();
        unawaited(close());
        return;
      }

      if (IsolateException.isValidMap(data)) {
        final exception = IsolateException.fromMap(data);
        _mainStreamController.addError(
          exception.error.toString(),
          StackTrace.empty,
        );
        return;
      }

      // There is an unhandled `type` of the `data`.
      _mainStreamController.addError(
        IsolateException('Unhandled $data from the Isolate').toString(),
      );
    }.toJS;
  }
  final Worker _delegate;

  final StreamController<R> _mainStreamController =
      StreamController.broadcast();

  final void Function()? _onDispose;
  final IsolateConverter<R> _workerConverter;
  final dynamic _initialParams;

  @override
  Completer<void> ensureInitialized = Completer();

  @override
  Worker get controller => _delegate;

  @override
  dynamic get initialParams => _initialParams;

  @override
  Stream<R> get onMessage => _mainStreamController.stream;

  @override
  Stream<P> get onIsolateMessage => throw UnimplementedError();

  @override
  Future<void> initialized() => throw UnimplementedError();

  @override
  void sendIsolate(P message) {
    _delegate.postMessage(jsify(message));
  }

  @override
  void sendIsolateState(IsolateState state) {
    _delegate.postMessage(jsify(state.toMap()));
  }

  @override
  void sendResult(R message) => throw UnimplementedError();

  @override
  void sendResultError(IsolateException exception) =>
      throw UnimplementedError();

  @override
  Future<void> close() async {
    _delegate.terminate();
    await _mainStreamController.close();
  }
}
