import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager/src/utils/check_subtype.dart';

/// A constant that is true if the application was compiled to WebAssembly.
const bool kIsWasm = bool.fromEnvironment('dart.tool.dart2wasm');

/// Converts [value] to type [R], handling numeric conversions for WASM.
R converterHelper<R>(dynamic value, [IsolateConverter<R>? customConverter]) {
  dynamic effectiveValue = value;
  if (kIsWasm) {
    if (isSubtype<R, int>()) {
      effectiveValue = (effectiveValue as num).toInt() as R;
    } else if (isSubtype<R, Iterable<int>>()) {
      effectiveValue =
          (effectiveValue as Iterable).cast<num>().map((e) => e.toInt()) as R;
    }
  }
  return customConverter?.call(effectiveValue) ?? effectiveValue as R;
}
