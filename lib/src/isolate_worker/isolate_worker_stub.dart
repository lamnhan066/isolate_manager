import 'isolate_worker.dart';

/// No-op on `io`.
void isolateWorkerImpl<R, P>(IsolateWorkerFunction<R, P> function) {
  throw UnimplementedError('Use only on the Web platform to create a Worker');
}
