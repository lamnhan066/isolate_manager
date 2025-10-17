import 'dart:async';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager/src/base/shared/function.dart';
import 'package:isolate_manager/src/utils/check_subtype.dart';
import 'package:isolate_manager/src/utils/converter.dart';
import 'package:isolate_manager/src/utils/print.dart';

/// Web platform does not need to use the `function`
Future<R> platformExecuteImpl<R extends Object?, P extends Object?>({
  required IsolateManager<Object?, dynamic> manager,
  required IsolateFunction<R, P> function,
  required P params,
  required String? workerFunction,
  required Object? workerParams,
  required bool priority,
  required bool enableWasmConverter,
}) async {
  final isWorker = manager.workerName != '';
  final isDebug = manager.isDebug;

  // Avoid running `wrap` and `unwrap` when the Worker is not available.
  if (!isWorker || (isWorker && workerFunction == null)) {
    debugPrinter(
      () =>
          isWorker
              ? 'Worker is available but `workerFunction` is null, '
                  'so `Future` will be used instead'
              : 'Worker is not available, '
                  'so `Future` will be used instead',
      debug: isDebug,
    );

    return function(params);
  }

  var finalParams = workerParams ?? params;
  final isUseIsolateType = finalParams is ImType;

  // Decode to a sendable object.
  if (isUseIsolateType) {
    finalParams = finalParams.unwrap;
  }

  var result = await manager.compute([
    workerFunction,
    finalParams,
    isUseIsolateType,
  ], priority: priority);

  // Encode to IsolateType.
  if (isImTypeSubtype<R>()) {
    result = ImType.wrap(result);
  }

  return converterHelper<R>(result, enableWasmConverter: enableWasmConverter);
}

/// Create a Worker on Web.
void workerFunctionImpl(Map<String, Function> map) {
  IsolateManagerFunction.workerFunction((List<dynamic> message) {
    return internalFunction([map[message[0]], message[1], message[2]]);
  });
}
