import 'dart:async';
import 'dart:js' as js;
import 'dart:js_util' as js_util;

import 'package:isolate_manager/isolate_manager.dart';
import 'package:web/web.dart';

/// Create a worker in your `main`.
///
/// ```dart
/// main() {
///   isolateWorker(myFunction);
/// }
/// ```
///
/// Build it with `dart compile js worker.dart -o worker.js -O4` and copy the `worker.js` to
/// your Web folder.
///
/// If you need to throw an exception, you should only throw the `message`
/// instead of a whole Object because it may not be shown as expected when
/// sending back to the main app.
///
/// ``` dart
///  return throw 'This is an error that you need to catch in your main app';
/// ```
void isolateWorker<R, P>(FutureOr<R> Function(P message) function) {
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
}

/// Internal function
Stream<T> callbackToStream<J, T>(
    String name, T Function(J jsValue) unwrapValue) {
  var controller = StreamController<T>.broadcast(sync: true);
  js_util.setProperty(js.context['self'], name, js.allowInterop((J event) {
    controller.add(unwrapValue(event));
  }));
  return controller.stream;
}

/// Internal function
void jsSendMessage(dynamic m) {
  js.context.callMethod('postMessage', [m]);
}
