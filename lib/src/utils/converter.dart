import 'package:isolate_manager/src/utils/check_subtype.dart';

/// A constant that is true if the application was compiled to WebAssembly.
const bool kIsWasm = bool.fromEnvironment('dart.tool.dart2wasm');

/// Converts [value] to type [R], handling numeric conversions for WASM.
R converterHelper<R>(dynamic value) {
  if (kIsWasm) {
    if (isSubtype<R, int>()) return (value as num).toInt() as R;
    if (isSubtype<R, Iterable<int>>()) {
      return (value as Iterable).cast<num>().map((e) => e.toInt()) as R;
    }
    if (isSubtype<R, List<int>>()) {
      return (value as List).cast<num>().map((e) => e.toInt()).toList() as R;
    }
  }
  return value as R;
}
