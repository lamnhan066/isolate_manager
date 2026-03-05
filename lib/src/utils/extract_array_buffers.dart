import 'dart:js_interop';
import 'dart:typed_data';

/// Extract JSArrayBuffers from Dart ByteBuffer/Uint8List objects for
/// zero-copy transfer via `postMessage`.
JSArray<JSArrayBuffer> extractArrayBuffers(List<Object> transferables) {
  final buffers = <JSArrayBuffer>[];

  for (final item in transferables) {
    // JS interop values in transfer lists are runtime-provided JSArrayBuffer objects.
    // We need this check so callers can pass raw JSArrayBuffer directly.
    // ignore: invalid_runtime_check_with_js_interop_types
    if (item is JSArrayBuffer) {
      buffers.add(item);
    } else if (item is ByteBuffer) {
      buffers.add(item.toJS);
    } else if (item is Uint8List) {
      buffers.add(item.buffer.toJS);
    }
    // Ignore non-transferable items silently
  }

  return buffers.toJS;
}
