import 'dart:async';
import 'dart:isolate';

import 'package:isolate_manager/src/base/contactor/isolate_contactor.dart';
import 'package:isolate_manager/src/base/contactor/isolate_contactor_controller/isolate_contactor_controller_stub.dart';
import 'package:isolate_manager/src/base/contactor/models/isolate_state.dart';

/// Internal instance
class IsolateContactorInternal<R, P> extends IsolateContactor<R, P> {
  /// Internal instance
  IsolateContactorInternal._({
    required CustomIsolateFunction isolateFunction,
    required dynamic isolateParam,
    required String workerName,
    required IsolateConverter<R> converter,
    // This parameter is needed on the web platform.
    // ignore: avoid_unused_constructor_parameters
    required IsolateConverter<R> workerConverter,
    required ReceivePort receivePort,
    super.debugMode,
  })  : _isolateFunction = isolateFunction,
        _workerName = workerName,
        _isolateParam = isolateParam,
        _receivePort = receivePort,
        _isolateContactorController = IsolateContactorControllerImpl(
          receivePort,
          converter: converter,
          workerConverter: workerConverter,
          onDispose: null,
          debugMode: debugMode,
        );

  /// Create receive port
  final ReceivePort _receivePort;

  /// Create isolate channel
  final IsolateContactorControllerImpl<R, P> _isolateContactorController;

  /// Create isolate
  Isolate? _isolate;

  /// Control the function of isolate
  final void Function(dynamic) _isolateFunction;

  /// Control the parameters of isolate
  final Object? _isolateParam;

  /// Only for web platform
  // ignore: unused_field
  final String _workerName;

  /// Create an instance with your own function
  static Future<IsolateContactorInternal<R, P>> createCustom<R, P>({
    required CustomIsolateFunction isolateFunction,
    required Object? initialParams,
    required String workerName,
    required IsolateConverter<R> converter,
    required IsolateConverter<R> workerConverter,
    bool debugMode = false,
  }) async {
    final isolateContactor = IsolateContactorInternal<R, P>._(
      isolateFunction: isolateFunction,
      workerName: workerName,
      isolateParam: initialParams,
      converter: converter,
      workerConverter: workerConverter,
      debugMode: debugMode,
      receivePort: ReceivePort(),
    );

    await isolateContactor._initial();

    return isolateContactor;
  }

  /// Initialize
  Future<void> _initial() async {
    _isolate = await Isolate.spawn(
      _isolateFunction,
      <Object?>[_isolateParam, _receivePort.sendPort],
    );

    await _isolateContactorController.ensureInitialized.future;
    printDebug(() => 'Initialized');
  }

  @override
  Stream<R> get onMessage => _isolateContactorController.onMessage;

  @override
  Future<void> dispose() async {
    _isolateContactorController.sendIsolateState(IsolateState.dispose);
    await _isolateContactorController.close();
    _receivePort.close();
    _isolate?.kill();
    _isolate = null;
    printDebug(() => 'Disposed');
  }

  @override
  Future<R> sendMessage(P message) async {
    printDebug(() => '[Main App] Message sent to isolate: $message');
    _isolateContactorController.sendIsolate(message);
    return _isolateContactorController.onMessage.first;
  }
}
