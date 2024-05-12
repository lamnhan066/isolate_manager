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
  if (onInitial != null) {
    final completer = Completer<void>();
    completer.complete(onInitial());
    await completer.future;
  }
  self.onmessage = (MessageEvent event) {
    final message = event.data;
    final Completer completer = Completer();
    completer.future.then(
      (value) => sendResult(value),
      onError: (err, stack) =>
          sendResult(IsolateException(err, stack).toJson()),
    );
    try {
      completer.complete(function(message as dynamic) as dynamic);
    } catch (err, stack) {
      completer.completeError(err, stack);
    }
  }.toJS;
  sendResult(IsolateState.initialized.toJson());
}

/// Internal function.
void sendResult(dynamic m) {
  self.postMessage(m);
}
