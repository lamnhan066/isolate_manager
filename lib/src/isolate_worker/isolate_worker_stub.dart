import 'dart:async';

void isolateWorker<R, P>(FutureOr<R> Function(P message) function) {
  throw UnimplementedError('Use only on the Web platform to create a Worker');
}
