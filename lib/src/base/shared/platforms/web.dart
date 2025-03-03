import 'dart:async';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager/src/base/shared/function.dart';
import 'package:isolate_manager/src/utils/check_subtype.dart';
import 'package:isolate_manager/src/utils/print.dart';

/// Web platform does not need to use the `function`
Future<R> platformExecuteImpl<R extends Object?, P extends Object?>({
  required IsolateManager<Object?, dynamic> manager,
  required IsolateFunction<R, P> function,
  required P params,
  required String? workerFunction,
  required Object? workerParams,
  required bool priority,
}) async {
  final isWorker = manager.workerName != '';
  final isDebug = manager.isDebug;
  if (isDebug && isWorker && workerFunction == null) {
    debugPrinter(
      () => 'Worker is available but `workerFunction` is null, '
          'so `Future` will be used instead',
    );
  }

  final func = (isWorker && workerFunction != null) ? workerFunction : function;
  var finalParams = workerParams ?? params;
  final isUseIsolateType = finalParams is IsolateType;

  // Decode to a sendable object.
  if (isUseIsolateType) {
    finalParams = finalParams.decode;
  }
  var result = await manager.compute(
    [func, finalParams, isUseIsolateType],
    priority: priority,
  );

  // Encode to IsolateType.
  if (isSubtype<R, IsolateType<Object?>>()) {
    result = IsolateType.encode<IsolateType<Object?>>(result);
  }

  return result as R;
}

/// Create a Worker on Web.
void workerFunctionImpl(Map<String, Function> map) {
  IsolateManagerFunction.workerFunction((List<dynamic> message) {
    return internalFunction([map[message[0]], message[1], message[2]]);
  });
}
