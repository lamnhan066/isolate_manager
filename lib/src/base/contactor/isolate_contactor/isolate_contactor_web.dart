import 'dart:async';

import '../isolate_contactor.dart';
import 'web_platform/isolate_contactor_web.dart';
import 'web_platform/isolate_contactor_web_worker.dart';

abstract class IsolateContactorInternal<R, P> extends IsolateContactor<R, P> {
  /// Constructer.
  const IsolateContactorInternal(super.debugMode);

  /// Create modified isolate function
  static Future<IsolateContactorInternal<R, P>> createCustom<R, P>({
    required CustomIsolateFunction isolateFunction,
    required String workerName,
    required Object? initialParams,
    required IsolateConverter<R> converter,
    required IsolateConverter<R> workerConverter,
    bool debugMode = false,
  }) async {
    /// If browser is not supported Worker then use Future
    if (workerName != '') {
      return IsolateContactorInternalWorker.createCustom<R, P>(
        isolateFunction: isolateFunction,
        workerName: workerName,
        initialParams: initialParams,
        converter: converter,
        workerConverter: workerConverter,
        debugMode: debugMode,
      );
    }
    return IsolateContactorInternalFuture.createCustom<R, P>(
      isolateFunction: isolateFunction,
      isolateFunctionName: workerName,
      initialParams: initialParams,
      converter: converter,
      workerConverter: workerConverter,
      debugMode: debugMode,
    );
  }
}
