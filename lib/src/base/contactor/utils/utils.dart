import 'dart:js_interop';

/// Returns Dart representation from JS Object.
Object? dartify(dynamic object) {
  // Convert JSObject to Dart equivalents directly
  // Cannot be done with Dart 3.2 constraints
  // ignore: invalid_runtime_check_with_js_interop_types
  if (object is! JSObject) {
    return object as Object?;
  }

  final jsObject = object;

  // Convert nested structures
  final dartObject = jsObject.dartify();
  return convertNested(dartObject);
}

/// Convert nested Map or List.
Object? convertNested(Object? object) {
  if (object is List) {
    return object.map(convertNested).toList();
  } else if (object is Map) {
    final map = <dynamic, dynamic>{};
    object.forEach((key, value) {
      map[key] = convertNested(value);
    });
    return map;
  } else {
    // For non-nested types, attempt to convert directly
    return dartify(object);
  }
}

/// Returns the JS implementation from Dart Object.
JSAny? jsify(Object? dartObject) {
  if (dartObject == null) {
    return dartObject.jsify();
  }

  if (dartObject is List) {
    return dartObject.map(jsify).toList().toJS;
  }

  if (dartObject is Map) {
    return dartObject
        .map((key, value) => MapEntry(jsify(key), jsify(value)))
        .jsify();
  }

  if (dartObject is JSAny Function()) {
    return dartObject.toJS;
  }

  return dartObject.jsify();
}
