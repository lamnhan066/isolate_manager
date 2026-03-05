import 'dart:typed_data';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager/src/utils/check_subtype.dart';

/// A constant that is true if the application was compiled to WebAssembly.
const bool kIsWasm = bool.fromEnvironment('dart.tool.dart2wasm');

/// Converts [value] to type [R], handling numeric conversions for WASM.
R converterHelper<R>(
  dynamic value, {
  IsolateConverter<R>? customConverter,
  bool enableWasmConverter = true,
}) {
  dynamic effectiveValue = value;
  // coverage:ignore-start
  if (enableWasmConverter && kIsWasm) {
    if (isSubtype<R, Uint8List>()) {
      if (effectiveValue is ByteBuffer) {
        effectiveValue = Uint8List.view(effectiveValue);
      } else if (effectiveValue is Iterable) {
        effectiveValue = Uint8List.fromList(
          effectiveValue.cast<num>().map((e) => e.toInt()).toList(),
        );
      }
    } else if (isSubtype<R, ByteBuffer>()) {
      if (effectiveValue is Uint8List) {
        effectiveValue = effectiveValue.buffer;
      } else if (effectiveValue is Iterable) {
        effectiveValue =
            Uint8List.fromList(
              effectiveValue.cast<num>().map((e) => e.toInt()).toList(),
            ).buffer;
      }
    } else if (isSubtype<R, int>()) {
      effectiveValue = (effectiveValue as num).toInt() as R;
    } else if (isSubtype<R, Iterable<int>>()) {
      effectiveValue = (effectiveValue as Iterable).cast<num>().map(
        (e) => e.toInt(),
      );

      if (isSubtype<R, List<int>>()) {
        effectiveValue = effectiveValue.toList() as R;
      } else if (isSubtype<R, Set<int>>()) {
        effectiveValue = effectiveValue.toSet() as R;
      }
    }
  }
  // coverage:ignore-end
  return customConverter?.call(effectiveValue) ?? effectiveValue as R;
}
