import 'dart:async';

import 'package:isolate_manager/src/base/contactor/isolate_contactor/isolate_contactor_web.dart';
import 'package:isolate_manager/src/base/contactor/isolate_contactor_controller/isolate_contactor_controller_web.dart';
import 'package:isolate_manager/src/base/isolate_contactor.dart';

/// Create an instance
class IsolateContactorInternalFuture<R, P>
    extends IsolateContactorInternal<R, P> {
  /// Create an instance
  IsolateContactorInternalFuture._({
    required IsolateCustomFunction isolateFunction,
    required Object? isolateParam,
    required IsolateConverter<R> converter,
    required IsolateConverter<R> workerConverter,
    super.debugMode,
  })  : _isolateFunction = isolateFunction,
        _isolateParam = isolateParam,
        _isolateContactorController = IsolateContactorControllerImpl(
          StreamController<dynamic>.broadcast(),
          converter: converter,
          workerConverter: workerConverter,
          onDispose: null,
          debugMode: debugMode,
        ) {
    _isolateFunction([_isolateParam, _isolateContactorController]);
  }

  /// Listener for result
  final IsolateContactorController<R, P> _isolateContactorController;

  /// Control the function of isolate
  final void Function(dynamic) _isolateFunction;

  /// Control the parameters of isolate
  final dynamic _isolateParam;

  /// Create modified isolate function
  static Future<IsolateContactorInternalFuture<R, P>> createCustom<R, P>({
    required IsolateCustomFunction isolateFunction,
    required String isolateFunctionName,
    required dynamic initialParams,
    required IsolateConverter<R> converter,
    required IsolateConverter<R> workerConverter,
    bool debugMode = false,
  }) async {
    final isolateContactor = IsolateContactorInternalFuture<R, P>._(
      isolateFunction: isolateFunction,
      isolateParam: initialParams ?? <dynamic>[],
      converter: converter,
      workerConverter: workerConverter,
      debugMode: debugMode,
    );

    await isolateContactor._initial();

    return isolateContactor;
  }

  /// Initialize
  Future<void> _initial() async {
    await _isolateContactorController.ensureInitialized.future;

    printDebug(() => 'Initialized');
  }

  @override
  Stream<R> get onMessage => _isolateContactorController.onMessage;

  @override
  Future<void> dispose() async {
    _isolateContactorController.sendIsolateState(IsolateState.dispose);
    await _isolateContactorController.close();
    printDebug(() => 'Disposed');
  }

  @override
  Future<R> sendMessage(P message) async {
    printDebug(() => '[Main App] Message sent to the Web Future: $message');
    _isolateContactorController.sendIsolate(message);
    return _isolateContactorController.onMessage.first;
  }
}
