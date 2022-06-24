// ignore_for_file: avoid_web_libraries_in_flutter, depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:js/js.dart' as pjs;
import 'package:js/js_util.dart' as js_util;

@pjs.JS('self')
external dynamic get globalScopeSelf;

// dart compile js isolate.dart -o isolate.js

main() {
  callbackToStream('onmessage', (html.MessageEvent e) {
    return js_util.getProperty(e, 'data');
  }).listen((message) async {
    // TODO: Function for computation here
    final result = await functionName(message);

    jsSendMessage(result);
  });
}

/// Modify your function here
dynamic functionName(dynamic message) => message;

Stream<T> callbackToStream<J, T>(
    String name, T Function(J jsValue) unwrapValue) {
  var controller = StreamController<T>.broadcast(sync: true);
  js_util.setProperty(js.context['self'], name, js.allowInterop((J event) {
    controller.add(unwrapValue(event));
  }));
  return controller.stream;
}

void jsSendMessage(dynamic m) {
  js.context.callMethod('postMessage', [jsonEncode(m)]);
}
