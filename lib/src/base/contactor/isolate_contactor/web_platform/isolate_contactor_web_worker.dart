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
    required CustomIsolateFunction isolateFunction,
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
        );

  /// Check for current cumputing state in enum with listener
  final StreamController<R> _mainStreamController =
      StreamController.broadcast();

  /// Listener for result
  final IsolateContactorController<R, P> _isolateContactorController;

  // final _isolateWorker = Worker("isolate.dart.js");

  /// Control the function of isolate
  // ignore: unused_field
  final void Function(dynamic) _isolateFunction;

  /// Control the parameters of isolate
  // ignore: unused_field
  final dynamic _isolateParam;

  /// Create modified isolate function
  static Future<IsolateContactorInternalWorker<R, P>> createCustom<R, P>({
    required CustomIsolateFunction isolateFunction,
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
    _isolateContactorController.onMessage.listen((message) {
      printDebug(
        () => '[Main Stream] Message received from Worker: $message',
      );
      _mainStreamController.sink.add(message);
    }).onError((Object err, StackTrace stack) {
      printDebug(
        () => '[Main Stream] Error message received from Worker: $err',
      );
      _mainStreamController.sink.addError(err, stack);
    });

    await _isolateContactorController.ensureInitialized.future;

    printDebug(() => 'Initialized');
  }

  @override
  Stream<R> get onMessage => _mainStreamController.stream;

  @override
  Future<void> dispose() async {
    _isolateContactorController.sendIsolateState(IsolateState.dispose);

    await _isolateContactorController.close();
    await _mainStreamController.close();

    printDebug(() => 'Disposed');
  }

  @override
  Future<R> sendMessage(P message) async {
    final completer = Completer<R>();
    final sub = _isolateContactorController.onMessage.listen((result) async {
      if (!completer.isCompleted) completer.complete(result);
    })
      ..onError((Object err, StackTrace stack) async {
        if (!completer.isCompleted) completer.completeError(err, stack);
      });

    try {
      printDebug(() => 'Message sent to isolate: $message');
      _isolateContactorController.sendIsolate(message);
      return await completer.future;
    } finally {
      await sub.cancel();
    }
  }
}
