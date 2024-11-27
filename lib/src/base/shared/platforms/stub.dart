import 'dart:async';

import 'package:isolate_manager/isolate_manager.dart';

/// Execute
Future<R> platformExecuteImpl<R extends Object?, P extends Object?>({
  required IsolateManager<Object?, dynamic> manager,
  required IsolateFunction<R, P> function,
  required P params,
  required String? workerFunction,
  required Object? workerParams,
  required bool priority,
}) async {
  final result = await manager.compute(
    [function, params],
    priority: priority,
  );
  return result as R;
}

/// Create a Worker on Web.
void workerFunctionImpl(Map<String, Function> map) {
  throw UnimplementedError('Only implemented on the Web for the Worker');
}
