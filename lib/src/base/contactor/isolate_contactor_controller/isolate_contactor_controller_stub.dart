import 'dart:async';
import 'dart:isolate';

import 'package:isolate_manager/src/base/contactor/isolate_contactor_controller.dart';
import 'package:isolate_manager/src/base/contactor/models/exception.dart';
import 'package:isolate_manager/src/base/contactor/models/isolate_port.dart';
import 'package:isolate_manager/src/base/contactor/models/isolate_state.dart';
import 'package:isolate_manager/src/utils/print.dart';
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
    required bool debugMode,
  })  : _debugMode = debugMode,
        _onDispose = onDispose,
        _converter = converter,
        _initialParams = params is List ? params.first : null,
        _delegate = params is List
            ? IsolateChannel.connectSend(params.last as SendPort)
            : IsolateChannel.connectReceive(params as ReceivePort),
        _mainStreamController = StreamController<R>.broadcast(),
        _isolateStreamController = StreamController<P>.broadcast() {
    _streamSubscription = _delegate.stream.listen(
      _handleEvent,
      onError: _mainStreamController.addError,
    );
  }

  final IsolateChannel<dynamic> _delegate;
  final StreamController<R> _mainStreamController;
  final StreamController<P> _isolateStreamController;
  final void Function()? _onDispose;
  final R Function(dynamic)? _converter;
  final dynamic _initialParams;
  late final StreamSubscription<dynamic> _streamSubscription;
  final bool _debugMode;

  @override
  final Completer<void> ensureInitialized = Completer<void>();

  @override
  dynamic get initialParams => _initialParams;

  @override
  Stream<R> get onMessage => _mainStreamController.stream;

  @override
  Stream<P> get onIsolateMessage => _isolateStreamController.stream;

  @override
  void initialized() {
    _delegate.sink.add({IsolatePort.main: IsolateState.initialized});
  }

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
      _mainStreamController.close(),
      _isolateStreamController.close(),
      _streamSubscription.cancel(),
    ]);
  }

  Future<void> _handleEvent(dynamic event) async {
    if (event is! Map<IsolatePort, dynamic>) return;

    for (final entry in event.entries) {
      switch (entry.key) {
        case IsolatePort.main:
          _handleMainPort(entry.value);
        case IsolatePort.isolate:
          await _handleIsolatePort(entry.value);
      }
    }
  }

  void _handleMainPort(dynamic value) {
    debugPrinter(
      () => '[Main App] Message received from the Isolate: $value',
      debug: _debugMode,
    );
    switch (value) {
      case == IsolateState.initialized:
        if (!ensureInitialized.isCompleted) {
          ensureInitialized.complete();
        }
      case final IsolateException e:
        _mainStreamController.addError(e.error, e.stackTrace);
      default:
        try {
          _mainStreamController.add(_converter?.call(value) ?? value as R);
        } catch (e, stack) {
          _mainStreamController.addError(e, stack);
        }
    }
  }

  Future<void> _handleIsolatePort(dynamic value) async {
    debugPrinter(
      () => '[Isolate] Message received from the Main App: $value',
      debug: _debugMode,
    );
    switch (value) {
      case == IsolateState.dispose:
        _onDispose?.call();
        await close();
      default:
        try {
          _isolateStreamController.add(value as P);
        } catch (e, stack) {
          _isolateStreamController.addError(e, stack);
        }
    }
  }
}
