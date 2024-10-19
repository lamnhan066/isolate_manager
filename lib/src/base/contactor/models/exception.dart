/// This [IsolateException] mainly use to transfer an [Exception] between an `Isolate` and
/// the main app.
class IsolateException implements Exception {
  /// Error object.
  final Object error;

  /// StackTrace.
  final StackTrace stack;

  /// This [IsolateException] mainly use to transfer an [Exception] between an `Isolate` and
  /// the main app.
  IsolateException(this.error, [this.stack = StackTrace.empty]);

  /// Convert to JSON.
  Map<String, dynamic> toMap() => {
        'type': r'$IsolateException',
        'value': {
          'error': error.toString(),
          'stack': stack.toString(),
        },
      };

  /// Convert from JSON.
  factory IsolateException.fromMap(Map map) {
    assert(isValidMap(map),
        'json should be checked by `isValidObject` before using');

    final values = map['value'];

    return IsolateException(
      values['error'],
      StackTrace.fromString(values['stack']),
    );
  }

  /// Check if the [map] is a valid [IsolateException].
  static bool isValidMap(Map map) {
    return map.containsKey('type') && map['type'] == r'$IsolateException';
  }
}
