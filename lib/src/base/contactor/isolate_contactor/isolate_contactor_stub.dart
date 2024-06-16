import 'dart:async';
import 'dart:isolate';

import 'package:isolate_manager/src/base/contactor/models/isolate_state.dart';

import '../isolate_contactor.dart';
import '../isolate_contactor_controller/isolate_contactor_controller_stub.dart';

class IsolateContactorInternal<R, P> extends IsolateContactor<R, P> {
  /// Create receive port
  late ReceivePort _receivePort;

  /// Create isolate channel
  late IsolateContactorControllerImpl<R, P> _isolateContactorController;

  /// Create isolate
  Isolate? _isolate;

  /// Check for current computing state in enum with listener
  final StreamController<R> _mainStreamController =
      StreamController.broadcast();

  /// Control the function of isolate
  late void Function(dynamic) _isolateFunction;

  /// Control the parameters of isolate
  late Object? _isolateParam;

  /// Only for web platform
  // ignore: unused_field
  late String _workerName;

  IsolateConverter<R>? _converter;
  IsolateConverter<R>? _workerConverter;

  /// Internal instance
  IsolateContactorInternal._({
    required CustomIsolateFunction isolateFunction,
    required dynamic isolateParam,
    required String workerName,
    required IsolateConverter<R> converter,
    required IsolateConverter<R> workerConverter,
    bool debugMode = false,
  }) : super(debugMode) {
    _isolateFunction = isolateFunction;
    _workerName = workerName;
    _converter = converter;
    _workerConverter = workerConverter;
    _isolateParam = isolateParam;
  }

  /// Create an instance with your own function
  static Future<IsolateContactorInternal<R, P>> createCustom<R, P>({
    required CustomIsolateFunction isolateFunction,
    required Object? initialParams,
    required String workerName,
    required IsolateConverter<R> converter,
    required IsolateConverter<R> workerConverter,
    bool debugMode = false,
  }) async {
    IsolateContactorInternal<R, P> isolateContactor =
        IsolateContactorInternal._(
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
    _receivePort = ReceivePort();
    _isolateContactorController = IsolateContactorControllerImpl(
      _receivePort,
      converter: _converter,
      workerConverter: _workerConverter,
      onDispose: null,
    );
    _isolateContactorController.onMessage.listen((message) {
      printDebug(() => 'Message received from Isolate: $message');
      _mainStreamController.sink.add(message);
    }).onError((err, stack) {
      printDebug(() => 'Error message received from Isolate: $err');
      _mainStreamController.sink.addError(err, stack);
    });

    _isolate = await Isolate.spawn(
        _isolateFunction, [_isolateParam, _receivePort.sendPort]);

    await _isolateContactorController.ensureInitialized.future;
    printDebug(() => 'Initialized');
  }

  Future<void> _dispose() async {
    _isolateContactorController.sendIsolateState(IsolateState.dispose);
    await _isolateContactorController.close();
    _receivePort.close();
    _isolate!.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
  }

  /// Get current message as stream
  @override
  Stream<R> get onMessage => _mainStreamController.stream;

  /// Dispose current [Isolate]
  @override
  Future<void> dispose() async {
    await _dispose();
    await _mainStreamController.close();
    printDebug(() => 'Disposed');
  }

  /// Send message to child isolate [function]
  ///
  /// Throw IsolateContactorException if error occurs.
  @override
  Future<R> sendMessage(P message) async {
    final Completer<R> completer = Completer();
    StreamSubscription? sub;
    sub = _isolateContactorController.onMessage.listen((result) async {
      if (!completer.isCompleted) {
        completer.complete(result);
        await sub?.cancel();
      }
    })
      ..onError((err, stack) async {
        completer.completeError(err, stack);
        await sub?.cancel();
      });

    printDebug(() => 'Message send to isolate: $message');

    _isolateContactorController.sendIsolate(message);

    return completer.future;
  }
}