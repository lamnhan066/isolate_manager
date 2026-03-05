import 'dart:typed_data';

import 'package:isolate_manager/src/isolate_manager.dart';

/// Extension to add automatic cross-platform transfer support to IsolateManagerController.
///
/// Automatically uses:
/// - TransferableTypedData on native platforms (when transferables are provided)
/// - ArrayBuffer transfer list on web platforms
extension AutoTransferExtension<R, P> on IsolateManagerController<R, P> {
  /// Send result with automatic zero-copy transfer detection.
  ///
  /// On web: Extracts ArrayBuffers from Uint8List/ByteBuffer in [result]
  /// On native: Uses TransferableTypedData for extracted buffers
  ///
  /// Example:
  /// ```dart
  /// final bytes = Uint8List(1024);
  /// controller.sendResultWithAutoTransfer({'data': bytes});
  /// ```
  void sendResultWithAutoTransfer(R result) {
    final transferables = _extractTransferables(result);
    sendResult(result, transferables: transferables);
  }

  /// Recursively extract transferable objects from a data structure.
  ///
  /// Searches through Maps and Lists to find Uint8List/ByteBuffer objects
  /// and collects them for zero-copy transfer.
  List<Object> _extractTransferables(dynamic data) {
    final transferables = <Object>[];

    void extract(dynamic item) {
      if (item is ByteBuffer) {
        transferables.add(item);
      } else if (item is Uint8List) {
        transferables.add(item.buffer);
      } else if (item is Map) {
        item.values.forEach(extract);
      } else if (item is List) {
        item.forEach(extract);
      }
      // Ignore other types
    }

    extract(data);
    return transferables;
  }
}
