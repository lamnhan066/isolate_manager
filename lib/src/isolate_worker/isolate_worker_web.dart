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
  final controller = IsolateManagerController<R, P>(self);
  if (onInitial != null) {
    final completer = Completer<void>();
    completer.complete(onInitial());
    await completer.future;
  }
  controller.onIsolateMessage.listen((message) {
    final completer = Completer<R>();
    completer.future.then(
      controller.sendResult,
      onError: (Object err, StackTrace stack) =>
          controller.sendResultError(IsolateException(err, stack)),
    );
    try {
      completer.complete(function(message) as dynamic);
    } catch (err, stack) {
      completer.completeError(err, stack);
    }
  });
  controller.initialized();
}

/// Create a custom worker in your `main`.
void customWorkerFunctionImpl(IsolateWorkerFunction<void, dynamic> function) {
  function(self);
}
