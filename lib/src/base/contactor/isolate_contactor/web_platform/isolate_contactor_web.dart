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
        );

  /// Check for current cumputing state in enum with listener
  final StreamController<R> _mainStreamController =
      StreamController.broadcast();

  /// Listener for result
  final IsolateContactorController<R, P>? _isolateContactorController;

  /// Control the function of isolate
  final void Function(dynamic) _isolateFunction;

  /// Control the parameters of isolate
  final dynamic _isolateParam;

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
    _isolateContactorController!.onMessage.listen((message) {
      printDebug(
        () => '[Main Stream] Message received from Future: $message',
      );
      _mainStreamController.sink.add(message);
    }).onError((Object err, StackTrace stack) {
      printDebug(
        () => '[Main Stream] Error message received from Future: $err',
      );
      _mainStreamController.sink.addError(err, stack);
    });

    _isolateFunction([_isolateParam, _isolateContactorController]);

    await _isolateContactorController.ensureInitialized.future;

    printDebug(() => 'Initialized');
  }

  @override
  Stream<R> get onMessage => _mainStreamController.stream;

  @override
  Future<void> dispose() async {
    _isolateContactorController?.sendIsolateState(IsolateState.dispose);

    await _isolateContactorController?.close();
    await _mainStreamController.close();

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
    StreamSubscription<dynamic>? sub;
    sub = _isolateContactorController.onMessage.listen((result) async {
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

    _isolateContactorController.sendIsolate(message);

    return completer.future;
  }
}
