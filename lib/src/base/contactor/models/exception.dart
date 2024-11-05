/// This [IsolateException] mainly use to transfer an [Exception] between
/// an `Isolate` and the main app.
class IsolateException implements Exception {
  /// This [IsolateException] mainly use to transfer an [Exception] between
  /// an `Isolate` and the main app.
  IsolateException(this.error, [this.stack = StackTrace.empty]);

  /// Convert from JSON.
  factory IsolateException.fromMap(Map<dynamic, dynamic> map) {
    assert(
      isValidMap(map),
      'json should be checked by `isValidObject` before using',
    );

    final values = map['value'] as Map;

    return IsolateException(
      values['error'] as Object,
      StackTrace.fromString(values['stack'] as String),
    );
  }

  /// Error object.
  final Object error;

  /// StackTrace.
  final StackTrace stack;

  /// Convert to JSON.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': r'$IsolateException',
        'value': <String, String>{
          'error': error.toString(),
          'stack': stack.toString(),
        },
      };

  /// Check if the [map] is a valid [IsolateException].
  static bool isValidMap(Map<dynamic, dynamic> map) {
    return map['type'] == r'$IsolateException';
  }
}
