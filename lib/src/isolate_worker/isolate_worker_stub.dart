// coverage:ignore-file
// Tested by compiling to `js` for the Web Worker.

import 'dart:async';

import 'package:isolate_manager/src/isolate_manager_function.dart';

/// No-op on `io`.
Future<void> isolateWorkerImpl<R, P>(
  IsolateWorkerFunction<R, P> function,
  @Deprecated(
    'Use `onInit` instead. This API will be removed in v6.0.0 when we reach the stable release.',
  )
  FutureOr<void> Function()? onInitial,
  IsolateOnInitCallback<R, P>? onInit,
) {
  throw UnimplementedError('Use only on the Web platform to create a Worker');
}

/// No-op on `io`.
void customWorkerFunctionImpl<R, P>(
  IsolateWorkerFunction<void, dynamic> function,
) {
  throw UnimplementedError('Use only on the Web platform to create a Worker');
}
