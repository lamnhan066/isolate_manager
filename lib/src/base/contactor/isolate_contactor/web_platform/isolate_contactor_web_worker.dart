import 'dart:async';
import 'dart:js_interop';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:web/web.dart';

import '../../isolate_contactor.dart';
import '../../isolate_contactor_controller.dart';
import '../../isolate_contactor_controller/isolate_contactor_controller_web.dart';
import '../isolate_contactor_web.dart';

class IsolateContactorInternalWorker<R, P>
    extends IsolateContactorInternal<R, P> {
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

  /// Create an instance
  IsolateContactorInternalWorker._({
    required CustomIsolateFunction isolateFunction,
    required Object? isolateParam,
    required String workerName,
    required IsolateConverter<R> converter,
    required IsolateConverter<R> workerConverter,
    bool debugMode = false,
  })  : _isolateFunction = isolateFunction,
        _isolateParam = isolateParam,
        super(debugMode) {
    // This is a workaround to support a wider range of `web` package versions (>=0.5.1 <2.0.0).
    // In the next major release (v6.0.0), only `$workerName.js'.toJS` will be used,
    // which requires `web` package version 1.0.0 or higher.
    try {
      _isolateContactorController = IsolateContactorControllerImpl(
        Worker('$workerName.js' as dynamic),
        converter: converter,
        workerConverter: workerConverter,
        onDispose: null,
      );
    } catch (_) {
      _isolateContactorController = IsolateContactorControllerImpl(
        Worker('$workerName.js'.toJS as dynamic),
        converter: converter,
        workerConverter: workerConverter,
        onDispose: null,
      );
    }
  }

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

  /// Get current message as stream
  @override
  Stream<R> get onMessage => _mainStreamController.stream;

  /// Dispose current [Isolate]
  @override
  Future<void> dispose() async {
    _isolateContactorController?.sendIsolateState(IsolateState.dispose);

    await _isolateContactorController?.close();
    await _mainStreamController.close();

    _isolateContactorController = null;

    printDebug(() => 'Disposed');
  }

  /// Send message to child isolate [function].
  ///
  /// Throw IsolateContactorException if error occurs.
  @override
  Future<R> sendMessage(P message) {
    final Completer<R> completer = Completer();
    late final StreamSubscription<R> sub;
    sub = _isolateContactorController!.onMessage.listen((result) async {
      if (!completer.isCompleted) {
        completer.complete(result);
        await sub.cancel();
      }
    })
      ..onError((Object err, StackTrace stack) async {
        completer.completeError(err, stack);
        await sub.cancel();
      });

    printDebug(() => 'Message send to isolate: $message');

    _isolateContactorController!.sendIsolate(message);

    return completer.future;
  }
}
