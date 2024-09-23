import 'dart:async';

import 'package:isolate_manager/isolate_manager.dart';

import '../function.dart';

/// Web platform does not need to use the `function`
Future<R> platformExecuteImpl<R extends Object, P extends Object>({
  required IsolateManager<Object, Object> manager,
  required IsolateFunction<R, P> function,
  required P params,
  required String? workerFunction,
  required Object? workerParams,
  required bool priority,
}) async {
  final isWorker = manager.workerName != '';
  final isDebug = manager.isDebug;
  if (isDebug && isWorker && workerFunction == null) {
    print('[Isolate Manager] Worker is available but `workerFunction` is null, '
        'so `Future` will be used instead');
  }

  final func = (isWorker && workerFunction != null) ? workerFunction : function;
  final finalParams = workerParams ?? params;
  return (await manager.compute([func, finalParams], priority: priority)) as R;
}

/// Create a Worker on Web.
void workerFunctionImpl(Map<String, Function> map) {
  IsolateManagerFunction.workerFunction((List<Object> message) {
    return internalFunction([map[message[0]] as Function, message[1]]);
  });
}
