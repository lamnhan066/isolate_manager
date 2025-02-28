import 'dart:async';

import 'package:isolate_manager/src/base/contactor/isolate_contactor/isolate_contactor_web.dart';
import 'package:isolate_manager/src/base/contactor/isolate_contactor_controller/isolate_contactor_controller_web.dart';
import 'package:isolate_manager/src/base/isolate_contactor.dart';

/// Create an instance
class IsolateContactorInternalFuture<R, P>
    extends IsolateContactorInternal<R, P> {
  /// Create an instance
  IsolateContactorInternalFuture._({
    required CustomIsolateFunction isolateFunction,
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
        ) {
    _streamSubscription = _isolateContactorController.onMessage.listen(
      (message) {
        printDebug(
          () => '[Main Stream] Message received from Future: $message',
        );
        _mainStreamController.sink.add(message);
      },
      onError: (Object err, StackTrace stack) {
        printDebug(
          () => '[Main Stream] Error message received from Future: $err',
        );
        _mainStreamController.sink.addError(err, stack);
      },
    );

    _isolateFunction([_isolateParam, _isolateContactorController]);
  }

  /// Check for current cumputing state in enum with listener
  final StreamController<R> _mainStreamController =
      StreamController.broadcast();

  /// Listener for result
  final IsolateContactorController<R, P> _isolateContactorController;

  /// Control the function of isolate
  final void Function(dynamic) _isolateFunction;

  /// Control the parameters of isolate
  final dynamic _isolateParam;

  late final StreamSubscription<dynamic> _streamSubscription;

  /// Create modified isolate function
  static Future<IsolateContactorInternalFuture<R, P>> createCustom<R, P>({
    required CustomIsolateFunction isolateFunction,
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
  Stream<R> get onMessage => _mainStreamController.stream;

  @override
  Future<void> dispose() async {
    _isolateContactorController.sendIsolateState(IsolateState.dispose);

    await Future.wait([
      _isolateContactorController.close(),
      _mainStreamController.close(),
      _streamSubscription.cancel(),
    ]);

    printDebug(() => 'Disposed');
  }

  @override
  Future<R> sendMessage(P message) async {
    printDebug(() => 'Message sent to isolate: $message');
    _isolateContactorController.sendIsolate(message);
    return _isolateContactorController.onMessage.first;
  }
}
