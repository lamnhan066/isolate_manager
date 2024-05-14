import 'dart:async';

import '../isolate_contactor.dart';
import 'web_platform/isolate_contactor_web.dart';
import 'web_platform/isolate_contactor_web_worker.dart';

abstract class IsolateContactorInternal<R, P>
    implements IsolateContactor<R, P> {
  /// Create modified isolate function
  static Future<IsolateContactorInternal<R, P>> createCustom<R, P>({
    required CustomIsolateFunction isolateFunction,
    required String workerName,
    required Object? initialParams,
    required IsolateConverter<R> converter,
    required IsolateConverter<R> workerConverter,
    required bool autoMarkAsInitialized,
    bool debugMode = false,
  }) async {
    /// If browser is not supported Worker then use Future
    if (workerName != '') {
      try {
        return IsolateContactorInternalWorker.createCustom(
          isolateFunction: isolateFunction,
          workerName: workerName,
          initialParams: initialParams,
          converter: converter,
          workerConverter: workerConverter,
          autoMarkAsInitialized: autoMarkAsInitialized,
          debugMode: debugMode,
        );
      } catch (_) {
        if (debugMode) {
          print(
              '[${IsolateContactor.debugLogPrefix}]: This browser doesn\'t support Worker, Future will be applied!');
        }
      }
    }
    return IsolateContactorInternalFuture.createCustom(
      isolateFunction: isolateFunction,
      isolateFunctionName: workerName,
      initialParams: initialParams,
      converter: converter,
      workerConverter: workerConverter,
      autoMarkAsInitialized: autoMarkAsInitialized,
      debugMode: debugMode,
    );
  }

  @override
  Future<void> dispose() {
    throw UnimplementedError();
  }

  @override
  Stream<R> get onMessage => throw UnimplementedError();

  @override
  Future<R> sendMessage(P message) {
    throw UnimplementedError();
  }
}
