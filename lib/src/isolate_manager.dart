import 'dart:async';
import 'dart:collection';

import 'package:isolate_contactor/isolate_contactor.dart';

import 'utils.dart';

class IsolateManager<R> {
  /// Number of concurrent isolates
  final int numOfIsolates;

  /// Isolate function
  final dynamic Function(dynamic) isolateFunction;

  /// Initial parameters
  final dynamic initialParams;

  /// Is using your own isolate function
  final bool isOwnIsolate;

  /// Allow print debug log
  final bool isDebug;

  /// Similar to `stream`, for who's using IsolateContactor
  Stream<R> get onMessage => _streamController.stream;

  /// Get value as stream
  Stream<R> get stream => _streamController.stream;

  IsolateManager._({
    required this.numOfIsolates,
    required this.isolateFunction,
    this.initialParams,
    this.isOwnIsolate = false,
    this.isDebug = false,
  });

  factory IsolateManager.create({
    required int numOfIsolates,
    required FutureOr<R> Function(dynamic) isolateFunction,
    bool isDebug = false,
  }) =>
      IsolateManager._(
        numOfIsolates: numOfIsolates,
        isolateFunction: isolateFunction,
        isDebug: isDebug,
      );

  factory IsolateManager.createOwnIsolate({
    required int numOfIsolates,
    required void Function(dynamic) isolateFunction,
    bool isDebug = false,
  }) =>
      IsolateManager._(
        numOfIsolates: numOfIsolates,
        isolateFunction: isolateFunction,
        isOwnIsolate: true,
        isDebug: isDebug,
      );

  /// Queue of isolates
  final Queue<IsolateQueue<R>> _queue = Queue();

  /// Map<IsolateContactor instance, isBusy>
  final Map<IsolateContactor<R>, bool> _isolates = {};

  /// Controller for stream
  final StreamController<R> _streamController = StreamController.broadcast();
  StreamSubscription<R>? _streamSubscription;

  /// Start initialize IsolateManager
  Future<void> start() async {
    if (isOwnIsolate) {
      await Future.wait(
        [
          for (int i = 0; i < numOfIsolates; i++)
            IsolateContactor.createOwnIsolate<R>(
              isolateFunction,
              isolateParams: initialParams,
              debugMode: isDebug,
            ).then((value) => _isolates.addAll({value: false}))
        ],
      );
    } else {
      await Future.wait(
        [
          for (int i = 0; i < numOfIsolates; i++)
            IsolateContactor.create<R>(
              isolateFunction as FutureOr<R> Function(dynamic),
              debugMode: isDebug,
            ).then((value) => _isolates.addAll({value: false}))
        ],
      );
    }

    // _streamController = StreamController.broadcast();
    for (final isolate in _isolates.keys) {
      _streamSubscription = isolate.onMessage.listen((value) {
        _streamController.sink.add(value);
        if (_queue.isNotEmpty) {
          final queue = _queue.removeFirst();
          _excute(isolate, queue);
        }
      });

      /// Allow calling `compute` before `start`
      if (_queue.isNotEmpty) {
        final queue = _queue.removeFirst();
        _excute(isolate, queue);
      }
    }
  }

  /// Stop isolate manager without close streamController
  Future<void> _tempStop() async {
    _queue.clear();
    await Future.wait(
        [for (final isolate in _isolates.keys) isolate.dispose()]);
    _isolates.clear();
    await _streamSubscription?.cancel();
  }

  /// Stop isolate manager
  Future<void> stop() async {
    _tempStop();
    await _streamController.close();
  }

  Future<void> restart() async {
    await _tempStop();
    await start();
  }

  ///  Similar to `commpute`, for who's using IsolateContactor
  Future<R> sendMessage(dynamic params) => compute(params);

  /// Compute isolate manager
  Future<R> compute(dynamic params) async {
    final queue = IsolateQueue<R>(params);

    for (final isolate in _isolates.keys) {
      if (_isolates[isolate] == false) {
        return _excute(isolate, queue);
      }
    }

    _queue.add(queue);

    return queue.completer.future;
  }

  Future<R> _excute(IsolateContactor<R> isolate, IsolateQueue<R> queue) async {
    _isolates[isolate] = true;

    isolate.sendMessage(queue.params).then((value) {
      queue.completer.complete(value);
      _isolates[isolate] = false;
    });

    return queue.completer.future;
  }
}
