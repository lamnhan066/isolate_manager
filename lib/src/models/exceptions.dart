/// A factory function type for creating [IsolateException] instances.
///
/// Parameters:
///   [error] - The error message or object
///   [stackTrace] - The stack trace associated with the exception
typedef IsolateExceptionFactory = IsolateException Function(
  Object error,
  StackTrace stackTrace,
);

/// An exception that can be safely transferred between isolates.
///
/// This class provides serialization and deserialization capabilities
/// for exceptions, allowing them to cross isolate boundaries while
/// preserving type information and stack traces.
class IsolateException implements Exception {
  /// Creates a new [IsolateException].
  ///
  /// Parameters:
  ///   [error] - The error message or object
  ///   [stackTrace] - The stack trace associated with the exception
  const IsolateException(
    this.error, [
    this.stackTrace = StackTrace.empty,
    this.name = '',
  ]);

  /// Creates an [IsolateException] from a serialized map.
  ///
  /// The map must have been created by [toMap] and validated with [isValidMap].
  ///
  /// Returns the appropriate subclass of [IsolateException] if one is registered
  /// with the matching [name].
  factory IsolateException.fromMap(Map<dynamic, dynamic> map) {
    assert(
      isValidMap(map),
      'json should be checked by `isValidMap` before using',
    );

    final name = map['name'] as String;
    final values = map['value'] as Map<dynamic, dynamic>;
    final error = values['e'] as Object;
    final stackTrace = StackTrace.fromString(values['s'] as String);

    // Try to create a specific subclass instance based on the registered factories
    for (final factory in _registeredFactories) {
      final exception = factory(error, stackTrace);
      if (exception.name == name) {
        return exception;
      }
    }

    // Fall back to basic IsolateException if no matching subclass is found
    return IsolateException(error, stackTrace);
  }

  /// Registry of exception factories for deserialization.
  ///
  /// This list contains factory functions for all registered exception types
  /// that can be deserialized from JSON.
  static final List<IsolateExceptionFactory> _registeredFactories = [
    IsolateException.new,
    UnsupportedImTypeWrappingException.new,
  ];

  /// Registers a custom exception type for serialization across isolates.
  ///
  /// Each subclass of [IsolateException] must be registered before it can be
  /// properly deserialized when crossing isolate boundaries.
  ///
  /// Parameters:
  ///   [factory] - A factory function that creates instances of this exception type
  ///
  /// Throws an [AssertionError] if the factory is already registered.
  static void register(IsolateExceptionFactory factory) {
    assert(
      !_registeredFactories.contains(factory),
      'This exception factory is already registered',
    );
    _registeredFactories.add(factory);
  }

  /// Unregisters a previously registered exception factory.
  ///
  /// After unregistering, exceptions of this type will be deserialized as
  /// generic [IsolateException] instances.
  ///
  /// Parameters:
  ///   [factory] - The factory function to unregister
  static void unregister(IsolateExceptionFactory factory) {
    _registeredFactories.remove(factory);
  }

  /// Subtype identifier for this exception.
  ///
  /// Used during serialization to identify the concrete subclass. The base
  /// [IsolateException] class uses an empty string as its [name].
  final String name;

  /// The original error object or message.
  final Object error;

  /// The stack trace where the exception occurred.
  final StackTrace stackTrace;

  /// Serializes this exception to a map that can be sent across isolates.
  ///
  /// Returns a map containing the exception type, name, error message, and stack trace.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': r'$IsolateException',
        'name': name,
        'value': <String, String>{
          'e': error.toString(),
          's': stackTrace.toString(),
        },
      };

  /// Checks if the given [map] represents a valid [IsolateException].
  ///
  /// Returns true if the map has the correct format and type marker.
  static bool isValidMap(Map<dynamic, dynamic> map) {
    return map['type'] == r'$IsolateException';
  }

  @override
  String toString() => '$name: $error\n$stackTrace';
}

/// An exception thrown when an unsupported type is encountered during isolate operations.
///
/// This exception is typically thrown when attempting to pass objects that cannot be
/// serialized between isolates.
class UnsupportedImTypeWrappingException extends IsolateException {
  /// Creates a new [UnsupportedImTypeWrappingException].
  ///
  /// Parameters:
  ///   [error] - The error message or unsupported object
  ///   [stackTrace] - The stack trace associated with the exception
  const UnsupportedImTypeWrappingException(
    super.error, [
    super.stackTrace = StackTrace.empty,
  ]);

  @override
  String get name => 'UnsupportedImTypeWrappingException';
}
