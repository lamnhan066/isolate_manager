import 'dart:async';
import 'dart:js_interop';

import 'package:isolate_manager/src/base/contactor/isolate_contactor_controller/isolate_contactor_controller_web.dart';
import 'package:isolate_manager/src/base/isolate_contactor.dart';
import 'package:isolate_manager/src/models/isolate_types.dart';
import 'package:isolate_manager/src/utils/check_subtype.dart';
import 'package:web/web.dart';

/// Implementation using [Worker] as the communication channel.
class IsolateContactorControllerImplWorker<R, P>
    implements IsolateContactorControllerImpl<R, P> {
  /// Implementation of the [IsolateContactorController] in `web` with `Worker`.
  IsolateContactorControllerImplWorker(
    dynamic params, {
    required void Function()? onDispose,
    required R Function(dynamic) workerConverter,
  })  : _workerConverter = workerConverter,
        _onDispose = onDispose,
        _delegate = params is List
            ? (params.last as IsolateContactorControllerImpl).controller
                as Worker
            : params as Worker,
        _initialParams = params is List ? params.first : null,
        _mainStreamController = StreamController<R>.broadcast() {
    _delegate.onmessage = _handleMessage.toJS;
  }

  final Worker _delegate;
  final void Function()? _onDispose;
  final IsolateConverter<R> _workerConverter;
  final dynamic _initialParams;
  final StreamController<R> _mainStreamController;

  @override
  final Completer<void> ensureInitialized = Completer<void>();

  @override
  Worker get controller => _delegate;

  @override
  dynamic get initialParams => _initialParams;

  @override
  Stream<R> get onMessage => _mainStreamController.stream;

  @override
  Stream<P> get onIsolateMessage =>
      throw UnimplementedError('onIsolateMessage is not implemented');

  @override
  Future<void> initialized() =>
      throw UnimplementedError('initialized method is not implemented');

  @override
  void sendIsolate(P message) {
    if (message is IsolateType<Object?>) {
      _delegate.postMessage(message.decode.jsify());
    } else {
      _delegate.postMessage(message.jsify());
    }
  }

  @override
  void sendIsolateState(IsolateState state) {
    _delegate.postMessage(state.toMap().jsify());
  }

  @override
  void sendResult(R message) =>
      throw UnimplementedError('sendResult is not implemented');

  @override
  void sendResultError(IsolateException exception) =>
      throw UnimplementedError('sendResultError is not implemented');

  @override
  Future<void> close() async {
    _delegate.terminate();
    await _mainStreamController.close();
  }

  /// Centralizes the event processing for the incoming worker messages.
  Future<void> _handleMessage(MessageEvent event) async {
    try {
      final data = event.data.dartify() as Map?;
      if (data == null) return;

      if (data['type'] == 'data') {
        var result = data['value'];
        if (isSubtype<R, IsolateType<Object?>>()) {
          result = IsolateType.encode(result);
        }
        _mainStreamController.add(_workerConverter(result));
        return;
      }

      if (IsolateState.initialized.isValidMap(data)) {
        if (!ensureInitialized.isCompleted) ensureInitialized.complete();
        return;
      }

      if (IsolateState.dispose.isValidMap(data)) {
        _onDispose?.call();
        await close();
        return;
      }

      if (IsolateException.isValidMap(data)) {
        _mainStreamController.addError(
          IsolateException.fromMap(data).error.toString(),
          StackTrace.empty,
        );
        return;
      }

      _mainStreamController.addError(
        IsolateException('Unhandled $data from the Isolate').error.toString(),
      );
    } catch (e, stack) {
      _mainStreamController.addError(e, stack);
    }
  }
}
