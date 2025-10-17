import 'dart:async';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager/src/base/shared/platforms/web.dart'
    if (dart.library.io) 'package:isolate_manager/src/base/shared/platforms/stub.dart';

/// Internal function
/// Values of [params]
///   0. Function
///   1. Parameter of the function
///   3. Is the parameter IsolateType
Future<dynamic> internalFunction(List<dynamic> params) async {
  final isIsolateTypeParameter = (params.elementAtOrNull(2) as bool?) ?? false;

  dynamic parameter = params[1];
  if (isIsolateTypeParameter) {
    parameter = ImType.wrap(parameter as Object);
  }
  final completer =
      Completer<dynamic>()..complete((params[0] as Function)(parameter));
  return completer.future;
}

/// Internal platform execute
Future<R> platformExecute<R extends Object?, P extends Object?>({
  required IsolateManager<Object?, dynamic> manager,
  required IsolateFunction<R, P> function,
  required P params,
  required String? workerFunction,
  required Object? workerParams,
  required bool priority,
  required bool enableWasmConverter,
}) async {
  return platformExecuteImpl<R, P>(
    manager: manager,
    function: function,
    params: params,
    workerFunction: workerFunction,
    workerParams: workerParams,
    priority: priority,
    enableWasmConverter: enableWasmConverter,
  );
}

/// Internal shared Worker function
void sharedWorkerFunctionImpl(Map<String, Function> map) {
  return workerFunctionImpl(map);
}
