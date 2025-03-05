import 'dart:async';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager/src/utils/converter.dart';

/// Execute
Future<R> platformExecuteImpl<R extends Object?, P extends Object?>({
  required IsolateManager<Object?, dynamic> manager,
  required IsolateFunction<R, P> function,
  required P params,
  required String? workerFunction,
  required Object? workerParams,
  required bool priority,
  required bool enableWasmConverter,
}) async {
  final result = await manager.compute(
    [function, params],
    priority: priority,
  );
  return converterHelper<R>(
    result,
    enableWasmConverter: enableWasmConverter,
  );
}

/// Create a Worker on Web.
void workerFunctionImpl(Map<String, Function> map) {
  throw UnimplementedError('Only implemented on the Web for the Worker');
}
