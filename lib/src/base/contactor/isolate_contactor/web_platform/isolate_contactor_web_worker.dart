import 'dart:async';
import 'dart:js_interop';

import 'package:isolate_manager/src/base/contactor/isolate_contactor.dart';
import 'package:isolate_manager/src/base/contactor/isolate_contactor/isolate_contactor_web.dart';
import 'package:isolate_manager/src/base/contactor/isolate_contactor_controller.dart';
import 'package:isolate_manager/src/base/contactor/isolate_contactor_controller/isolate_contactor_controller_web.dart';
import 'package:isolate_manager/src/base/contactor/models/exception.dart';
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
    required bool isWasmWorker,
    super.debugMode,
  })  : _isolateFunction = isolateFunction,
        _isolateParam = isolateParam,
        _isolateContactorController = IsolateContactorControllerImpl(
          Worker('$workerName.${isWasmWorker ? '.wasm' : '.js'}'.toJS),
          converter: converter,
          workerConverter: workerConverter,
          onDispose: null,
        );

  /// Check for current cumputing state in enum with listener
  final StreamController<R> _mainStreamController =
      StreamController.broadcast();

  /// Listener for result
  IsolateContactorController<R, P>? _isolateContactorController;

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
    required bool isWasmWorker,
    bool debugMode = false,
  }) async {
    final isolateContactor = IsolateContactorInternalWorker<R, P>._(
      isolateFunction: isolateFunction,
      workerName: workerName,
      isolateParam: initialParams,
      converter: converter,
      workerConverter: workerConverter,
      isWasmWorker: isWasmWorker,
      debugMode: debugMode,
    );

    await isolateContactor._initial();

    return isolateContactor;
  }

  /// Initialize
  Future<void> _initial() async {
    _isolateContactorController!.onMessage.listen((message) {
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

    await _isolateContactorController!.ensureInitialized.future;

    printDebug(() => 'Initialized');
  }

  @override
  Stream<R> get onMessage => _mainStreamController.stream;

  @override
  Future<void> dispose() async {
    _isolateContactorController?.sendIsolateState(IsolateState.dispose);

    await _isolateContactorController?.close();
    await _mainStreamController.close();

    _isolateContactorController = null;

    printDebug(() => 'Disposed');
  }

  @override
  Future<R> sendMessage(P message) {
    if (_isolateContactorController == null) {
      printDebug(() => '! This isolate has been terminated');
      return throw IsolateException(
        'This isolate was terminated',
      );
    }

    final completer = Completer<R>();
    StreamSubscription<R>? sub;
    sub = _isolateContactorController!.onMessage.listen((result) async {
      if (!completer.isCompleted) {
        completer.complete(result);
        await sub?.cancel();
      }
    })
      ..onError((Object err, StackTrace stack) async {
        completer.completeError(err, stack);
        await sub?.cancel();
      });

    printDebug(() => 'Message send to isolate: $message');

    _isolateContactorController!.sendIsolate(message);

    return completer.future;
  }
}
