// coverage:ignore-file
// Tested by compiling to `js` for the Web Worker.

import 'dart:async';
import 'dart:js_interop';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:web/web.dart';

@JS('self')
external DedicatedWorkerGlobalScope get self;

/// Create a worker in your `main`.
Future<void> isolateWorkerImpl<R, P>(
  IsolateWorkerFunction<R, P> function,
  FutureOr<void> Function()? onInitial,
) async {
  final controller = IsolateManagerController<R, MessageEvent>(
      ['DedicatedWorkerGlobalScope', self]);
  if (onInitial != null) {
    final completer = Completer<void>();
    completer.complete(onInitial());
    await completer.future;
  }
  controller.onIsolateMessage.listen((event) {
    final completer = Completer();
    completer.future.then(
      (value) => controller.sendResult(value),
      onError: (err, stack) =>
          controller.sendResultError(IsolateException(err, stack)),
    );
    try {
      final message = event.data as dynamic;
      completer.complete(function(message) as dynamic);
    } catch (err, stack) {
      completer.completeError(err, stack);
    }
  });
  controller.initialized();
}

/// Create a custom worker in your `main`.
void customWorkerFunctionImpl(IsolateWorkerFunction<void, dynamic> function) {
  function(['DedicatedWorkerGlobalScope', self]);
}
