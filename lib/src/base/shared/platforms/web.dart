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
}) async {
  final isWorker = manager.workerName != '';
  final isDebug = manager.isDebug;
  if (isDebug && isWorker && workerFunction == null) {
    print('[Isolate Manager] Worker is available but `workerFunction` is null, '
        'so `Future` will be used instead');
  }

  if (isWorker && workerFunction != null) {
    final finalParams = workerParams ?? params;
    return (await manager.compute([workerFunction, finalParams])) as R;
  } else {
    final completer = Completer<R>();
    completer.complete(function(params));
    return completer.future;
  }
}

/// Create a Worker on Web.
void workerFunctionImpl(Map<String, Function> map) {
  IsolateManagerFunction.workerFunction((List<Object> message) {
    return internalFunction([map[message[0]] as Function, message[1]]);
  });
}
