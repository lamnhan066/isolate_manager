import 'dart:async';
import 'dart:js_interop';

import 'package:isolate_manager/src/base/contactor/isolate_contactor_controller/isolate_contactor_controller_web.dart';
import 'package:isolate_manager/src/base/isolate_contactor.dart';
import 'package:isolate_manager/src/models/isolate_types.dart';
import 'package:isolate_manager/src/utils/check_subtype.dart';
import 'package:isolate_manager/src/utils/print.dart';
import 'package:web/web.dart';

/// Implementation using [Worker] as the communication channel.
class IsolateContactorControllerImplWorker<R, P>
    implements IsolateContactorControllerImpl<R, P> {
  /// Implementation of the [IsolateContactorController] in `web` with `Worker`.
  IsolateContactorControllerImplWorker(
    dynamic params, {
    required void Function()? onDispose,
    required R Function(dynamic) workerConverter,
    required bool debugMode,
  })  : _debugMode = debugMode,
        _workerConverter = workerConverter,
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
  final bool _debugMode;

  @override
  final Completer<void> ensureInitialized = Completer<void>();

  @override
  Worker get controller => _delegate;

  @override
  dynamic get initialParams => _initialParams;

  @override
  Stream<R> get onMessage => _mainStreamController.stream;

  @override
  void sendIsolate(P message) {
    if (message is IsolateType) {
      _delegate.postMessage(message.unwrap.jsify());
    } else {
      _delegate.postMessage(message.jsify());
    }
  }

  @override
  void sendIsolateState(IsolateState state) {
    _delegate.postMessage(state.toMap().jsify());
  }

  // TODO(lamnhan066): Find a way to test these methods because it only used by the compiled JS Worker.
  // coverage:ignore-start
  @override
  Stream<P> get onIsolateMessage =>
      throw UnimplementedError('onIsolateMessage is not implemented');

  @override
  Future<void> initialized() =>
      throw UnimplementedError('initialized method is not implemented');

  @override
  void sendResult(R message) =>
      throw UnimplementedError('sendResult is not implemented');

  @override
  void sendResultError(IsolateException exception) =>
      throw UnimplementedError('sendResultError is not implemented');
  // coverage:ignore-end

  @override
  Future<void> close() async {
    _delegate.terminate();
    await _mainStreamController.close();
  }

  /// Centralizes the event processing for the incoming worker messages.
  // Can't return `Future<void>` because of the `onmessage` signature.
  // ignore: avoid_void_async
  void _handleMessage(MessageEvent event) async {
    debugPrinter(
      () => '[Main App] Message received from the Web Worker: ${event.data}',
      debug: _debugMode,
    );

    try {
      final data = event.data.dartify() as Map?;

      if (data == null) return;

      if (data['type'] == 'data') {
        var result = data['value'];
        if (isIsolateTypeSubtype<R>()) {
          result = IsolateType.wrap(result as Object);
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
        _mainStreamController.addError(data);
        return;
      }

      _mainStreamController.addError(
        IsolateException('Unhandled $data from the Isolate').toMap(),
      );
    } catch (e, stack) {
      _mainStreamController.addError(IsolateException(e, stack).toMap());
    }
  }
}
