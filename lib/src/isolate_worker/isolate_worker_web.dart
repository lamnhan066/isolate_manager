// TODO(lamnhan066): Find a way to test these methods because it only used by the compiled JS Worker.
// coverage:ignore-file
// Tested by compiling to `js` for the Web Worker.

import 'dart:async';
import 'dart:js_interop';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:web/web.dart';

@JS('self')
external DedicatedWorkerGlobalScope get _self;

/// Create a worker in your `main`.
Future<void> isolateWorkerImpl<R, P>(
  IsolateWorkerFunction<R, P> function,
  @Deprecated(
    'Use `onInit` instead. This API will be removed in v6.0.0 when we reach the stable release.',
  )
  FutureOr<void> Function()? onInitial,
  IsolateOnInitCallback<R, P>? onInit,
) async {
  final controller = IsolateManagerController<R, P>(_self);

  await onInitial?.call();
  await onInit?.call(controller);

  controller.onIsolateMessage.listen((message) async {
    try {
      final result = await function(message);
      controller.sendResult(result);
    } catch (err, stack) {
      controller.sendResultError(IsolateException(err, stack));
    }
  });

  controller.initialized();
}

/// Create a custom worker in your `main`.
void customWorkerFunctionImpl(IsolateWorkerFunction<void, dynamic> function) {
  function(_self);
}
