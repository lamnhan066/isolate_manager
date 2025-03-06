/// This [IsolateException] mainly use to transfer an [Exception] between
/// an `Isolate` and the main app.
class IsolateException implements Exception {
  /// This [IsolateException] mainly use to transfer an [Exception] between
  /// an `Isolate` and the main app.
  IsolateException(this.error, [this.stackTrace = StackTrace.empty]);

  /// Convert from JSON.
  factory IsolateException.fromMap(Map<dynamic, dynamic> map) {
    assert(
      isValidMap(map),
      'json should be checked by `isValidMap` before using',
    );

    final values = map['value'] as Map;

    return IsolateException(
      values['e'] as Object,
      StackTrace.fromString(values['s'] as String),
    );
  }

  /// Error object.
  final Object error;

  /// StackTrace.
  final StackTrace stackTrace;

  /// Convert to JSON.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': r'$IsolateException',
        'value': <String, String>{
          'e': error.toString(),
          's': stackTrace.toString(),
        },
      };

  /// Check if the [map] is a valid [IsolateException].
  static bool isValidMap(Map<dynamic, dynamic> map) {
    return map['type'] == r'$IsolateException';
  }
}

/// An exception that is thrown when an unsupported type is encountered during isolate operations.
///
/// This exception is typically thrown when attempting to pass a type that cannot be serialized
/// or is not supported for communication between isolates.
class UnsupportedImTypeWrappingException extends IsolateException {
  /// Creates a new [UnsupportedImTypeWrappingException] instance.
  ///
  /// Parameters:
  ///   [error] - The error message or object that caused the exception
  ///   [stackTrace] - Optional stack trace associated with the exception, defaults to [StackTrace.empty]
  UnsupportedImTypeWrappingException(
    super.error, [
    super.stackTrace = StackTrace.empty,
  ]);
}
