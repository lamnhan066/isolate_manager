/// A factory function type for creating [IsolateException] instances.
///
/// Parameters:
///   [message] - The error message or object
///   [stackTrace] - The stack trace associated with the exception
typedef IsolateExceptionFactory = IsolateException Function(
  Object message, [
  StackTrace stackTrace,
]);

/// This [IsolateException] mainly use to transfer an [Exception] between
/// an `Isolate` and the main app.
class IsolateException implements Exception {
  /// This [IsolateException] mainly use to transfer an [Exception] between
  /// an `Isolate` and the main app.
  const IsolateException(
    this.error, [
    this.stackTrace = StackTrace.empty,
  ]) : _subType = '';

  /// Convert from JSON.
  factory IsolateException.fromMap(Map<dynamic, dynamic> map) {
    assert(
      isValidMap(map),
      'json should be checked by `isValidMap` before using',
    );

    final values = map['value'] as Map<dynamic, dynamic>;
    final subType = map['subType'] as String?;

    for (final entry in _registered.entries) {
      if (entry.key == subType) {
        return entry.value(
          values['e'] as Object,
          StackTrace.fromString(values['s'] as String),
        );
      }
    }

    return IsolateException(
      values['e'] as Object,
      StackTrace.fromString(values['s'] as String),
    );
  }

  static final Map<String, IsolateExceptionFactory> _registered = {
    '': IsolateException.new,
    'UnsupportedImTypeWrappingException':
        UnsupportedImTypeWrappingException.new,
  };

  /// Registers a custom exception type with the IsolateException system.
  ///
  /// This allows for serialization and deserialization of specialized exception types
  /// across isolate boundaries.
  ///
  /// Parameters:
  ///   [type] - A unique string identifier for this exception type
  ///   [exception] - A factory function that creates instances of this exception type
  ///
  /// Throws an assertion error if the type is already registered.
  static void register<E extends IsolateException>(
    String type,
    IsolateExceptionFactory exception,
  ) {
    assert(
      !_registered.containsKey(type),
      'The type $type is already registered',
    );
    _registered[type] = exception;
  }

  /// Returns the subtype of the exception.
  /// This is used for serialization to determine the specific type of exception.
  final String _subType;

  /// Error object.
  final Object error;

  /// StackTrace.
  final StackTrace stackTrace;

  /// Convert to JSON.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': r'$IsolateException',
        'subType': _subType,
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
  const UnsupportedImTypeWrappingException(
    super.error, [
    super.stackTrace = StackTrace.empty,
  ]);

  @override
  String get _subType => 'UnsupportedImTypeWrappingException';
}
