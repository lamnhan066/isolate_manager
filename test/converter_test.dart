import 'dart:typed_data';

import 'package:isolate_manager/src/utils/converter.dart';
import 'package:test/test.dart';

const bool _isWasm = bool.fromEnvironment('dart.tool.dart2wasm');

void main() {
  group('converterHelper', () {
    test('applies custom converter when provided', () {
      final result = converterHelper<String>(
        42,
        enableWasmConverter: false,
        customConverter: (value) => 'value:$value',
      );

      expect(result, 'value:42');
    });

    test('keeps values unchanged when wasm converter is disabled', () {
      final value = <int>[1, 2, 3];
      final result = converterHelper<List<int>>(
        value,
        enableWasmConverter: false,
      );

      expect(result, same(value));
    });

    test('converts to Uint8List in wasm mode', () {
      if (_isWasm) {
        final byteBuffer = Uint8List.fromList([10, 20, 30]).buffer;
        final fromBuffer = converterHelper<Uint8List>(byteBuffer);
        final fromIterable = converterHelper<Uint8List>([1.2, 2.9, 3.0]);

        expect(fromBuffer, [10, 20, 30]);
        expect(fromIterable, [1, 2, 3]);
      } else {
        final value = Uint8List.fromList([10, 20, 30]);
        final result = converterHelper<Uint8List>(value);
        expect(result, same(value));
      }
    });

    test('converts to ByteBuffer in wasm mode', () {
      if (_isWasm) {
        final uint8 = Uint8List.fromList([5, 6, 7]);
        final fromUint8 = converterHelper<ByteBuffer>(uint8);
        final fromIterable = converterHelper<ByteBuffer>([8.2, 9.9]);

        expect(Uint8List.view(fromUint8), [5, 6, 7]);
        expect(Uint8List.view(fromIterable), [8, 9]);
      } else {
        final value = Uint8List.fromList([5, 6, 7]).buffer;
        final result = converterHelper<ByteBuffer>(value);
        expect(result, same(value));
      }
    });

    test('converts num to int in wasm mode', () {
      if (_isWasm) {
        final result = converterHelper<int>(12.8);
        expect(result, 12);
      } else {
        expect(() => converterHelper<int>(12.8), throwsA(anything));
      }
    });

    test('converts Iterable<num> to Iterable<int>, List<int> and Set<int>', () {
      if (_isWasm) {
        final asIterable = converterHelper<Iterable<int>>([1.7, 2.1, 3.9]);
        final asList = converterHelper<List<int>>([4.7, 5.2]);
        final asSet = converterHelper<Set<int>>([6.1, 6.9, 7.0]);

        expect(asIterable, [1, 2, 3]);
        expect(asList, [4, 5]);
        expect(asSet, {6, 7});
      } else {
        final iterable = converterHelper<Iterable<int>>([1, 2, 3]);
        final list = converterHelper<List<int>>([4, 5]);
        final set = converterHelper<Set<int>>({6, 7});

        expect(iterable, [1, 2, 3]);
        expect(list, [4, 5]);
        expect(set, {6, 7});
      }
    });
  });
}
