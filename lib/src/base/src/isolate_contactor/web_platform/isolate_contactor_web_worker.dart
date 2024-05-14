import 'dart:async';

import 'package:isolate_manager/src/base/src/models/isolate_state.dart';
import 'package:web/web.dart';

import '../../isolate_contactor.dart';
import '../../isolate_contactor_controller.dart';
import '../../isolate_contactor_controller/isolate_contactor_controller_web.dart';
import '../../models/exception.dart';
import '../isolate_contactor_web.dart';

class IsolateContactorInternalWorker<R, P>
    implements IsolateContactorInternal<R, P> {
  /// For debugging
  bool _debugMode = false;

  /// Check for current cumputing state in enum with listener
  final StreamController<R> _mainStreamController =
      StreamController.broadcast();

  /// Listener for result
  IsolateContactorController<R, P>? _isolateContactorController;

  // final _isolateWorker = Worker("isolate.dart.js");

  /// Control the function of isolate
  // ignore: unused_field
  late void Function(dynamic) _isolateFunction;

  /// Control the parameters of isolate
  // ignore: unused_field
  late dynamic _isolateParam;

  late String _workerName;

  late IsolateConverter<R> _converter;
  late IsolateConverter<R> _workerConverter;

  /// Create an instance
  IsolateContactorInternalWorker._({
    required CustomIsolateFunction isolateFunction,
    required Object? isolateParam,
    required String workerName,
    required IsolateConverter<R> converter,
    required IsolateConverter<R> workerConverter,
    bool debugMode = false,
  }) {
    _debugMode = debugMode;
    _isolateFunction = isolateFunction;
    _workerName = workerName;
    _converter = converter;
    _workerConverter = workerConverter;
    _isolateParam = isolateParam;
  }

  /// Create modified isolate function
  static Future<IsolateContactorInternalWorker<R, P>> createCustom<R, P>({
    required void Function(dynamic) isolateFunction,
    required String workerName,
    required Object? initialParams,
    required IsolateConverter<R> converter,
    required IsolateConverter<R> workerConverter,
    bool debugMode = false,
  }) async {
    IsolateContactorInternalWorker<R, P> isolateContactor =
        IsolateContactorInternalWorker._(
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
    _isolateContactorController = IsolateContactorControllerImpl(
      Worker("$_workerName.js"),
      converter: _converter,
      workerConverter: _workerConverter,
      onDispose: null,
    );
    _isolateContactorController!.onMessage.listen((message) {
      _printDebug('[Main Stream] Message received from Worker: $message');
      _mainStreamController.sink.add(message);
    }).onError((err, stack) {
      _printDebug('[Main Stream] Error message received from Worker: $err');
      _mainStreamController.sink.addError(err, stack);
    });

    await _isolateContactorController!.ensureInitialized.future;

    _printDebug('Initialized');
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

    _printDebug('Disposed');
  }

  /// Send message to child isolate [function].
  ///
  /// Throw IsolateContactorException if error occurs.
  @override
  Future<R> sendMessage(P message) {
    if (_isolateContactorController == null) {
      _printDebug('! This isolate has been terminated');
      return throw IsolateException(
        'This isolate was terminated',
        StackTrace.empty,
      );
    }

    final Completer<R> completer = Completer();
    StreamSubscription? sub;
    sub = _isolateContactorController!.onMessage.listen((result) async {
      if (!completer.isCompleted) {
        completer.complete(result);
        await sub?.cancel();
      }
    })
      ..onError((err, stack) async {
        completer.completeError(err, stack);
        await sub?.cancel();
      });

    _printDebug('Message send to isolate: $message');

    _isolateContactorController!.sendIsolate(message);

    return completer.future;
  }

  /// Print if [debugMode] is true
  void _printDebug(Object? object, [bool force = false]) {
    // ignore: avoid_print
    if (_debugMode && !force) {
      print('[${IsolateContactor.debugLogPrefix}]: $object');
    }
  }
}
