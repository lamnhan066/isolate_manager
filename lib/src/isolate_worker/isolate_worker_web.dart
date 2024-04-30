// coverage:ignore-file
// Tested by compiling to `js` for the Web Worker.

import 'dart:async';
import 'dart:js' as js;
import 'dart:js_util' as js_util;

import 'package:isolate_contactor/isolate_contactor.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:web/web.dart';

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
  callbackToStream('onmessage', (MessageEvent e) {
    return js_util.getProperty(e, 'data');
  }).listen((message) {
    final Completer completer = Completer();
    completer.future.then(
      (value) => jsSendMessage(value),
      onError: (err, stack) =>
          jsSendMessage(IsolateException(err, stack).toJson()),
    );
    try {
      completer.complete(function(message as P) as R);
    } catch (err, stack) {
      jsSendMessage(IsolateException(err, stack).toJson());
    }
  });
  jsSendMessage(IsolateState.initialized.toJson());
}

/// Internal function.
Stream<T> callbackToStream<J, T>(
    String name, T Function(J jsValue) unwrapValue) {
  var controller = StreamController<T>.broadcast(sync: true);
  js_util.setProperty(js.context['self'], name, js.allowInterop((J event) {
    controller.add(unwrapValue(event));
  }));
  return controller.stream;
}

/// Internal function.
void jsSendMessage(dynamic m) {
  js.context.callMethod('postMessage', [m]);
}
