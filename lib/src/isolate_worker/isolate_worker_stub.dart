// coverage:ignore-file
// Tested by compiling to `js` for the Web Worker.

import 'dart:async';

import 'isolate_worker.dart';

/// No-op on `io`.
Future<void> isolateWorkerImpl<R, P>(
  IsolateWorkerFunction<R, P> function,
  FutureOr<void> Function()? onInitial,
) {
  throw UnimplementedError('Use only on the Web platform to create a Worker');
}
