import 'dart:async';

import '../isolate_manager_function.dart';

/// No-op on `io`.
Future<void> isolateWorkerImpl<R, P>(
  IsolateWorkerFunction<R, P> function,
  FutureOr<void> Function()? onInitial,
) {
  throw UnimplementedError('Use only on the Web platform to create a Worker');
}

/// No-op on `io`.
void customWorkerFunctionImpl<R, P>(
  IsolateWorkerFunction<void, dynamic> function,
) {
  throw UnimplementedError('Use only on the Web platform to create a Worker');
}
