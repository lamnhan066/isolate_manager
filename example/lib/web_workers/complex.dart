// ignore_for_file: avoid_web_libraries_in_flutter, depend_on_referenced_packages

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager_example/functions.dart';
import 'package:isolate_manager_example/models/complex_model.dart';
import 'package:js/js.dart' as pjs;
import 'package:js/js_util.dart' as js_util;

@pjs.JS('self')
external dynamic get globalScopeSelf;

/// dart compile js complex.dart -o complex.js -O4

/// In most cases you don't need to modify this function
main() {
  callbackToStream('onmessage', (html.MessageEvent e) {
    return js_util.getProperty(e, 'data');
  }).listen((message) async {
    final Completer completer = Completer();
    completer.future.then(
      (value) => jsSendMessage(value),
      onError: (err, stack) =>
          jsSendMessage(IsolateException(err, stack).toJson()),
    );
    try {
      completer.complete(worker(message));
    } catch (err, stack) {
      jsSendMessage(IsolateException(err, stack).toJson());
    }
  });
}

/// This worker will recieve a String data, convert it to [ComplexModelParam] and
/// use it to create a List of String, then store it in [ComplexModelResult] and
/// convert it to JSON before sending back to the main app.
FutureOr<dynamic> worker(dynamic message) {
  return complexFunction(message);
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
