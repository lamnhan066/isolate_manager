@TestOn('vm')
library;

import 'dart:isolate';
import 'dart:typed_data';

import 'package:isolate_manager/src/utils/native_transferable_codec.dart';
import 'package:test/test.dart';

void main() {
  group('native transferable codec', () {
    test('encode/decode round-trip for targeted Uint8List view', () {
      final source = Uint8List.fromList(List<int>.generate(16, (i) => i));
      final view = Uint8List.view(source.buffer, 4, 6);
      final payload = <String, Object?>{
        'bytes': view,
        'untouched': Uint8List.fromList(<int>[100, 101]),
      };

      final encoded = encodeNativeTransferPayload(
        payload,
        transferables: <Object>[source.buffer],
      );
      final decoded =
          decodeNativeTransferPayload(encoded) as Map<Object?, Object?>;

      final decodedBytes = decoded['bytes'] as Uint8List?;
      expect(decodedBytes, isNotNull);
      expect(decodedBytes, orderedEquals(view));
      expect(decodedBytes!.lengthInBytes, 6);
      expect(decoded['untouched'], isA<Uint8List>());
    });

    test('no transferables keeps payload identity', () {
      final payload = <String, Object?>{'bytes': Uint8List(8)};
      final encoded = encodeNativeTransferPayload(payload);
      expect(identical(encoded, payload), isTrue);
    });

    test('non-matching transferables keep payload identity', () {
      final payload = <String, Object?>{'bytes': Uint8List(8)};
      final other = Uint8List(4);

      final encoded = encodeNativeTransferPayload(
        payload,
        transferables: <Object>[other.buffer],
      );
      expect(identical(encoded, payload), isTrue);
    });

    test('supports TransferableTypedData in transferables list', () {
      final packet = TransferableTypedData.fromList([
        Uint8List.fromList(<int>[7, 8, 9]),
      ]);
      final payload = <String, Object?>{'packet': packet};

      final encoded = encodeNativeTransferPayload(
        payload,
        transferables: <Object>[packet],
      );
      final decoded =
          decodeNativeTransferPayload(encoded) as Map<Object?, Object?>;

      final decodedPacket = decoded['packet'] as TransferableTypedData?;
      expect(decodedPacket, isNotNull);
      expect(
        Uint8List.view(decodedPacket!.materialize()),
        orderedEquals(<int>[7, 8, 9]),
      );
    });

    test('accepts Uint8List directly in transferables (not .buffer)', () {
      final source = Uint8List.fromList(<int>[10, 20, 30, 40]);
      final payload = <String, Object?>{'bytes': source};

      final encoded = encodeNativeTransferPayload(
        payload,
        transferables: <Object>[source], // Uint8List, not source.buffer
      );
      final decoded =
          decodeNativeTransferPayload(encoded) as Map<Object?, Object?>;

      final decodedBytes = decoded['bytes'] as Uint8List?;
      expect(decodedBytes, isNotNull);
      expect(decodedBytes, orderedEquals(source));
    });

    test('encodes List payload containing targeted Uint8List', () {
      final source = Uint8List.fromList(<int>[1, 2, 3]);
      final payload = <Object?>[source, 'hello', 99];

      final encoded = encodeNativeTransferPayload(
        payload,
        transferables: <Object>[source.buffer],
      );
      final decoded = decodeNativeTransferPayload(encoded) as List;

      expect(decoded[0] as Uint8List, orderedEquals(source));
      expect(decoded[1], 'hello');
      expect(decoded[2], 99);
    });

    test('encodes Map with non-string keys', () {
      final source = Uint8List.fromList(<int>[5, 6, 7]);
      final payload = <Object?, Object?>{1: source, 'label': 'ok'};

      final encoded = encodeNativeTransferPayload(
        payload,
        transferables: <Object>[source.buffer],
      );
      final decoded =
          decodeNativeTransferPayload(encoded) as Map<Object?, Object?>;

      expect(decoded[1] as Uint8List?, orderedEquals(source));
      expect(decoded['label'], 'ok');
    });

    test('deduplicates packet when same buffer referenced twice', () {
      final source = Uint8List.fromList(<int>[10, 20, 30, 40]);
      final view1 = Uint8List.view(source.buffer, 0, 2);
      final view2 = Uint8List.view(source.buffer, 2, 2);
      final payload = <String, Object?>{'a': view1, 'b': view2};

      final encoded =
          encodeNativeTransferPayload(
                payload,
                transferables: <Object>[source.buffer],
              )
              as Map<String, Object?>;

      // Both views share the same buffer → only 1 packet in envelope
      final packets = encoded['packets'] as List<Object?>?;
      expect(packets, isNotNull);
      expect(packets!.length, 1);

      final decoded =
          decodeNativeTransferPayload(encoded) as Map<Object?, Object?>;
      expect(decoded['a'] as Uint8List?, orderedEquals(<int>[10, 20]));
      expect(decoded['b'] as Uint8List?, orderedEquals(<int>[30, 40]));
    });

    test('deduplicates packet when same TTD referenced twice', () {
      final packet = TransferableTypedData.fromList([
        Uint8List.fromList(<int>[1, 2, 3]),
      ]);
      final payload = <String, Object?>{'p1': packet, 'p2': packet};

      final encoded =
          encodeNativeTransferPayload(payload, transferables: <Object>[packet])
              as Map<String, Object?>;

      // Same TTD referenced twice → only 1 packet
      final packets = encoded['packets'] as List<Object?>?;
      expect(packets, isNotNull);
      expect(packets!.length, 1);
    });

    test('skips TransferableTypedData not in targetTransferables', () {
      final packet = TransferableTypedData.fromList([
        Uint8List.fromList(<int>[1, 2]),
      ]);
      final other = TransferableTypedData.fromList([
        Uint8List.fromList(<int>[3, 4]),
      ]);
      final payload = <String, Object?>{'p': packet};

      // other is in transferables, but packet is in the payload — no match
      final encoded = encodeNativeTransferPayload(
        payload,
        transferables: <Object>[other],
      );
      expect(identical(encoded, payload), isTrue);
    });

    test('skips ByteBuffer in payload not in targetBuffers', () {
      final buf1 = Uint8List.fromList(<int>[1, 2]).buffer;
      final buf2 = Uint8List.fromList(<int>[3, 4]).buffer;
      final payload = <String, Object?>{'b': buf1};

      // buf2 is in transferables, buf1 is in payload — no match
      final encoded = encodeNativeTransferPayload(
        payload,
        transferables: <Object>[buf2],
      );
      expect(identical(encoded, payload), isTrue);
    });

    test('unknown transferable type makes target sets empty → identity', () {
      final payload = <String, Object?>{'x': 1};

      final encoded = encodeNativeTransferPayload(
        payload,
        transferables: <Object>['not a buffer or TTD'],
      );
      expect(identical(encoded, payload), isTrue);
    });

    test('decode: non-Map payload returns as-is', () {
      expect(decodeNativeTransferPayload('hello'), 'hello');
      expect(decodeNativeTransferPayload(42), 42);
      expect(decodeNativeTransferPayload(null), null);
      expect(decodeNativeTransferPayload(<int>[1, 2]), <int>[1, 2]);
    });

    test('decode: Map without envelope marker returns as-is', () {
      final payload = <String, Object?>{'key': 'value', 'num': 1};
      final result = decodeNativeTransferPayload(payload);
      expect(identical(result, payload), isTrue);
    });

    test(
      'decode: malformed envelope with non-List packets returns payload',
      () {
        final fakeEnvelope = <String, Object?>{
          '__im_native_transfer_envelope__': true,
          'payload': 'raw',
          'packets': 'not-a-list',
        };
        expect(decodeNativeTransferPayload(fakeEnvelope), 'raw');
      },
    );

    test('decode: nested List in payload is traversed', () {
      final source = Uint8List.fromList(<int>[9, 8, 7]);
      final payload = <String, Object?>{
        'items': [source, 'text', 123],
      };

      final encoded = encodeNativeTransferPayload(
        payload,
        transferables: <Object>[source.buffer],
      );
      final decoded =
          decodeNativeTransferPayload(encoded) as Map<Object?, Object?>;

      final items = decoded['items'] as List<Object?>?;
      expect(items, isNotNull);
      expect(items![0] as Uint8List?, orderedEquals(source));
      expect(items[1], 'text');
      expect(items[2], 123);
    });

    test('decode: nested Map with non-string keys is traversed', () {
      final source = Uint8List.fromList(<int>[3, 2, 1]);
      final payload = <Object?, Object?>{42: source, 'str': 'val'};

      final encoded = encodeNativeTransferPayload(
        payload,
        transferables: <Object>[source.buffer],
      );
      final decoded =
          decodeNativeTransferPayload(encoded) as Map<Object?, Object?>;

      expect(decoded[42] as Uint8List?, orderedEquals(source));
      expect(decoded['str'], 'val');
    });
  });
}
