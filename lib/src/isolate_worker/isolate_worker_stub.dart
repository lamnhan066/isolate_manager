// TODO(lamnhan066): Find a way to test these methods because it only used by the compiled JS Worker.
// coverage:ignore-file
// Tested by compiling to `js` for the Web Worker.

import 'dart:async';

import 'package:isolate_manager/src/isolate_manager_function.dart';

/// No-op on `io`.
Future<void> isolateWorkerImpl<R, P>(
  IsolateWorkerFunction<R, P> function,
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
