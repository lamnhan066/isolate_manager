import 'dart:async';

import '../../../isolate_contactor.dart';
import '../../isolate_contactor_controller/isolate_contactor_controller_web.dart';
import '../isolate_contactor_web.dart';

class IsolateContactorInternalFuture<R, P>
    implements IsolateContactorInternal<R, P> {
  /// Check for current cumputing state in enum with listener
  final StreamController<R> _mainStreamController =
      StreamController.broadcast();

  /// Listener for result
  IsolateContactorController<R, P>? _isolateContactorController;

  /// Control the function of isolate
  late void Function(dynamic) _isolateFunction;

  /// Control the parameters of isolate
  late dynamic _isolateParam;

  // ignore: unused_field
  late String _workerName;

  late IsolateConverter<R> _converter;
  late IsolateConverter<R> _workerConverter;

  /// Create an instance
  IsolateContactorInternalFuture._({
    required CustomIsolateFunction isolateFunction,
    required String workerName,
    required Object? isolateParam,
    required IsolateConverter<R> converter,
    required IsolateConverter<R> workerConverter,
    d,
    bool debugMode = false,
  }) {
    _isolateFunction = isolateFunction;
    _workerName = workerName;
    _converter = converter;
    _workerConverter = workerConverter;
    _isolateParam = isolateParam;
  }

  /// Create modified isolate function
  static Future<IsolateContactorInternalFuture<R, P>> createCustom<R, P>({
    required void Function(dynamic) isolateFunction,
    required String isolateFunctionName,
    required dynamic initialParams,
    required IsolateConverter<R> converter,
    required IsolateConverter<R> workerConverter,
    bool debugMode = false,
  }) async {
    IsolateContactorInternalFuture<R, P> isolateContactor =
        IsolateContactorInternalFuture._(
      isolateFunction: isolateFunction,
      workerName: isolateFunctionName,
      isolateParam: initialParams ?? [],
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
      StreamController.broadcast(),
      converter: _converter,
      workerConverter: _workerConverter,
      onDispose: null,
    );
    _isolateContactorController!.onMessage.listen((message) {
      IsolateContactor.printDebug(
        () => '[Main Stream] Message received from Future: $message',
      );
      _mainStreamController.sink.add(message);
    }).onError((err, stack) {
      IsolateContactor.printDebug(
        () => '[Main Stream] Error message received from Future: $err',
      );
      _mainStreamController.sink.addError(err, stack);
    });

    _isolateFunction([_isolateParam, _isolateContactorController]);

    await _isolateContactorController!.ensureInitialized.future;

    IsolateContactor.printDebug(() => 'Initialized');
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

    IsolateContactor.printDebug(() => 'Disposed');
  }

  /// Send message to child isolate [function].
  ///
  /// Throw IsolateContactorException if error occurs.
  @override
  Future<R> sendMessage(P message) {
    if (_isolateContactorController == null) {
      IsolateContactor.printDebug(() => '! This isolate has been terminated');
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

    IsolateContactor.printDebug(() => 'Message send to isolate: $message');

    _isolateContactorController!.sendIsolate(message);

    return completer.future;
  }
}
