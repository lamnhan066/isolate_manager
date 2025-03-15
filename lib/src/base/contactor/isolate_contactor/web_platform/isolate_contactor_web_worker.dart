import 'dart:async';
import 'dart:js_interop';

import 'package:isolate_manager/src/base/contactor/isolate_contactor.dart';
import 'package:isolate_manager/src/base/contactor/isolate_contactor/isolate_contactor_web.dart';
import 'package:isolate_manager/src/base/contactor/isolate_contactor_controller.dart';
import 'package:isolate_manager/src/base/contactor/isolate_contactor_controller/isolate_contactor_controller_web.dart';
import 'package:isolate_manager/src/base/contactor/models/isolate_state.dart';
import 'package:web/web.dart';

/// Create an instance
class IsolateContactorInternalWorker<R, P>
    extends IsolateContactorInternal<R, P> {
  /// Create an instance
  IsolateContactorInternalWorker._({
    required IsolateCustomFunction isolateFunction,
    required Object? isolateParam,
    required String workerName,
    required IsolateConverter<R> converter,
    required IsolateConverter<R> workerConverter,
    super.debugMode,
  })  : _isolateFunction = isolateFunction,
        _isolateParam = isolateParam,
        _isolateContactorController = IsolateContactorControllerImpl(
          Worker('$workerName.js'.toJS),
          converter: converter,
          workerConverter: workerConverter,
          onDispose: null,
          debugMode: debugMode,
        );

  /// Listener for result
  final IsolateContactorController<R, P> _isolateContactorController;

  /// Control the function of isolate
  // ignore: unused_field
  final void Function(dynamic) _isolateFunction;

  /// Control the parameters of isolate
  // ignore: unused_field
  final dynamic _isolateParam;

  /// Create modified isolate function
  static Future<IsolateContactorInternalWorker<R, P>> createCustom<R, P>({
    required IsolateCustomFunction isolateFunction,
    required String workerName,
    required Object? initialParams,
    required IsolateConverter<R> converter,
    required IsolateConverter<R> workerConverter,
    bool debugMode = false,
  }) async {
    final isolateContactor = IsolateContactorInternalWorker<R, P>._(
      isolateFunction: isolateFunction,
      workerName: workerName,
      isolateParam: initialParams,
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
    printDebug(() => '[Main App] Message sent to the Web Worker: $message');
    _isolateContactorController.sendIsolate(message);
    return _isolateContactorController.onMessage.first;
  }
}
