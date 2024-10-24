import 'dart:convert';

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
  String toJson() => jsonEncode({
        r'$IsolateException': {
          'error': error.toString(),
          'stack': stack.toString(),
        }
      });

  /// Convert from JSON.
  factory IsolateException.fromJson(dynamic json) {
    assert(isValidObject(json),
        'json should be checked by `isValidObject` before using');

    final decoded = jsonDecode(json.toString());
    final values = decoded[r'$IsolateException'];

    return IsolateException(
      values['error'],
      StackTrace.fromString(values['stack']),
    );
  }

  /// Check if the [input] is a valid [IsolateException].
  static bool isValidObject(dynamic input) {
    if (input is! String) return false;

    try {
      final decoded = jsonDecode(input) as Map;
      return decoded.containsKey(r'$IsolateException');
    } catch (_) {}
    return false;
  }
}
