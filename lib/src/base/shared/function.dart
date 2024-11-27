import 'dart:async';

import 'package:isolate_manager/isolate_manager.dart';

import 'platforms/web.dart' if (dart.library.io) 'platforms/stub.dart';

/// Internal function
Future<Object?> internalFunction(List<Object?> params) async {
  // assert(params is List, 'params is not a list');
  assert(params.length == 2, 'params must have only 2 elements');
  assert(params[0] is Function, 'params[0] is not a Function');

  final completer = Completer<Object?>();
  completer.complete((params[0] as Function)(params[1]));
  return completer.future;
}

/// Internal platform execute
Future<R> platformExecute<R extends Object?, P extends Object?>({
  required IsolateManager<Object?, dynamic> manager,
  required FutureOr<R> Function(P) function,
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
