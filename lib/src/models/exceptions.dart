import 'package:isolate_manager/isolate_manager.dart';

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
