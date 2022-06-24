// ignore_for_file: avoid_web_libraries_in_flutter, depend_on_referenced_packages

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:js/js.dart' as pjs;
import 'package:js/js_util.dart' as js_util;

@pjs.JS('self')
external dynamic get globalScopeSelf;

// dart compile js fibonacci.dart -o fibonacci.js

main() {
  callbackToStream('onmessage', (html.MessageEvent e) {
    return js_util.getProperty(e, 'data');
  }).listen((message) async {
    // TODO: Function for computation here
    final result = fibonacci(message);

    jsSendMessage(result);
  });
}

/// This must be a static or top-level function
int fibonacci(dynamic n) {
  if (n == 0) return 0;
  if (n <= 2) return 1;

  double n1 = 0, n2 = 1, n3 = 1;

  for (int i = 2; i <= n; i++) {
    n3 = n1 + n2;
    n1 = n2;
    n2 = n3;
  }

  return n3.round();
}

Stream<T> callbackToStream<J, T>(
    String name, T Function(J jsValue) unwrapValue) {
  var controller = StreamController<T>.broadcast(sync: true);
  js_util.setProperty(js.context['self'], name, js.allowInterop((J event) {
    controller.add(unwrapValue(event));
  }));
  return controller.stream;
}

void jsSendMessage(dynamic m) {
  js.context.callMethod('postMessage', [m]);
}
