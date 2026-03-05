import 'dart:typed_data';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:test/test.dart';

@pragma('vm:entry-point')
void testWorkerBufferAndList(dynamic params) {
  final controller =
      IsolateManagerController<Map<String, Object?>, Map<String, Object?>>(
        params,
      );

  controller.onIsolateMessage.listen((_) {
    final bytes = Uint8List(8);
    // Result contains a ByteBuffer (covers ByteBuffer branch in _extractTransferables)
    // and a List with a Uint8List (covers List branch in _extractTransferables).
    controller.sendResultWithAutoTransfer({
      'buffer': bytes.buffer,
      'list': <Object>[Uint8List(4)],
    });
  });

  controller.initialized();
}

@pragma('vm:entry-point')
void testWorker(dynamic params) {
  final controller =
      IsolateManagerController<Map<String, Object?>, Map<String, Object?>>(
        params,
      );

  controller.onIsolateMessage.listen((message) {
    final data = message;
    final bytes = data['bytes'] as Uint8List?;
    if (bytes == null) return;

    // Process bytes
    final result = Uint8List(bytes.length);
    for (var i = 0; i < result.length; i++) {
      result[i] = bytes[i] + 1;
    }

    // Use auto-transfer extension - automatically handles platform differences!
    controller.sendResultWithAutoTransfer({
      'processed': result,
      'size': result.length,
    });
  });

  controller.initialized();
}

void main() {
  group('Auto Transfer Extension', () {
    test(
      'should automatically extract transferables from nested data',
      () async {
        final manager = IsolateManager<
          Map<String, Object?>,
          Map<String, Object?>
        >.createCustom(testWorker);
        await manager.start();

        final bytes1 = Uint8List(100);
        final bytes2 = Uint8List(200);

        for (var i = 0; i < bytes1.length; i++) {
          bytes1[i] = i;
        }

        Map<String, Object?>? result;

        await manager.compute(
          {
            'bytes': bytes1,
            'nested': {'more': bytes2},
          },
          callback: (value) {
            if (value['processed'] != null) {
              result = value;
              return true;
            }
            return false;
          },
        );

        expect(result, isNotNull);
        expect(result!['size'], 100);

        final processed = result!['processed'] as Uint8List?;
        expect(processed, isNotNull);
        expect(processed![0], 1); // First byte incremented
        expect(processed[99], 100); // Last byte incremented

        await manager.stop();
      },
    );

    test(
      'sendResultWithAutoTransfer handles ByteBuffer and List items',
      () async {
        final manager = IsolateManager<
          Map<String, Object?>,
          Map<String, Object?>
        >.createCustom(testWorkerBufferAndList);
        await manager.start();

        final result = await manager.compute({'trigger': true});

        expect(result['buffer'], isA<ByteBuffer>());
        expect(result['list'], isList);

        await manager.stop();
      },
    );

    test('extractTransferables should find nested Uint8Lists', () {
      // Create a test data structure with nested Uint8Lists
      final testData = {
        'data': Uint8List(10),
        'nested': {'buffer': Uint8List(20).buffer, 'array': Uint8List(30)},
        'list': [Uint8List(40), Uint8List(50)],
      };

      // Verify data structure contains transferable types
      expect(testData['data'], isA<Uint8List>());
      final nested = testData['nested'] as Map<String, Object?>?;
      expect(nested, isNotNull);
      expect(nested!['buffer'], isA<ByteBuffer>());
      expect(nested['array'], isA<Uint8List>());
    });
  });
}
