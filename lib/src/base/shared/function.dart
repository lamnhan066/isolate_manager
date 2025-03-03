import 'dart:async';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager/src/base/shared/platforms/web.dart'
    if (dart.library.io) 'package:isolate_manager/src/base/shared/platforms/stub.dart';

/// Internal function
/// Values of [params]
///   0. Function
///   1. Parameter of the function
Future<dynamic> internalFunction(List<dynamic> params) async {
  final completer = Completer<dynamic>()
    ..complete((params[0] as Function)(params[1]));
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
}) async {
  return platformExecuteImpl<R, P>(
    manager: manager,
    function: function,
    params: params,
    workerFunction: workerFunction,
    workerParams: workerParams,
    priority: priority,
  );
}

/// Internal shared Worker function
void sharedWorkerFunctionImpl(Map<String, Function> map) {
  return workerFunctionImpl(map);
}
