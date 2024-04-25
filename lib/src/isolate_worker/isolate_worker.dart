import 'dart:async';

import 'isolate_worker_web.dart'
    if (dart.library.io) 'isolate_worker_stub.dart';

typedef IsolateWorkerFunction<R, P> = FutureOr<R> Function(P message);

void isolateWorker<R, P>(IsolateWorkerFunction<R, P> function) {
  return isolateWorkerImpl<R, P>(function);
}
