@TestOn('vm')
library;

import 'dart:isolate';
import 'dart:typed_data';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:test/test.dart';

@pragma('vm:entry-point')
Map<String, Object?> echoMap(Map<String, Object?> value) => value;

@pragma('vm:entry-point')
void transferResultWorker(dynamic params) {
  final controller =
      IsolateManagerController<Map<String, Object?>, Map<String, Object?>>(
        params,
      );

  controller.onIsolateMessage.listen((message) {
    final source = message['bytes'] as Uint8List?;
    if (source == null) return;

    final processed = Uint8List.fromList(
      source.map((byte) => (byte + 1) % 256).toList(),
    );

    controller.sendResult(
      <String, Object?>{'processed': processed},
      transferables: <Object>[processed.buffer],
    );
  });

  controller.initialized();
}

@pragma('vm:entry-point')
void transferablePacketWorker(dynamic params) {
  final controller =
      IsolateManagerController<Map<String, Object?>, Map<String, Object?>>(
        params,
      );

  controller.onIsolateMessage.listen((message) {
    final packet = message['packet'] as TransferableTypedData?;
    if (packet == null) return;
    final bytes = Uint8List.view(packet.materialize());
    controller.sendResult(<String, Object?>{
      'sum': bytes.reduce((a, b) => a + b),
    });
  });

  controller.initialized();
}

void main() {
  group('Native transferables', () {
    test('round-trip Uint8List view with transferables', () async {
      final manager = IsolateManager.create(echoMap);
      await manager.start();

      final bytes = Uint8List.fromList(List<int>.generate(64, (i) => i));
      final view = Uint8List.view(bytes.buffer, 8, 16);

      final result = await manager.compute(
        <String, Object?>{'bytes': view},
        transferables: <Object>[bytes.buffer],
      );

      final returned = result['bytes'] as Uint8List?;
      expect(returned, isNotNull);
      expect(returned, orderedEquals(view));
      expect(returned!.lengthInBytes, 16);

      await manager.stop();
    });

    test('round-trip ByteBuffer with transferables', () async {
      final manager = IsolateManager.create(echoMap);
      await manager.start();

      final bytes = Uint8List.fromList(List<int>.generate(32, (i) => i * 2));

      final result = await manager.compute(
        <String, Object?>{'buffer': bytes.buffer},
        transferables: <Object>[bytes.buffer],
      );

      final returnedBuffer = result['buffer'] as ByteBuffer?;
      expect(returnedBuffer, isNotNull);
      expect(returnedBuffer!.lengthInBytes, bytes.buffer.lengthInBytes);
      expect(Uint8List.view(returnedBuffer), orderedEquals(bytes));

      await manager.stop();
    });

    test('worker to main sendResult supports transferables', () async {
      final manager = IsolateManager<
        Map<String, Object?>,
        Map<String, Object?>
      >.createCustom(transferResultWorker);
      await manager.start();

      final input = Uint8List.fromList(<int>[1, 2, 3, 250]);
      final result = await manager.compute(<String, Object?>{'bytes': input});
      final processed = result['processed'] as Uint8List?;

      expect(processed, isNotNull);
      expect(processed, orderedEquals(<int>[2, 3, 4, 251]));

      await manager.stop();
    });

    test(
      'main to worker supports TransferableTypedData in transferables',
      () async {
        final manager = IsolateManager<
          Map<String, Object?>,
          Map<String, Object?>
        >.createCustom(transferablePacketWorker);
        await manager.start();

        final packet = TransferableTypedData.fromList([
          Uint8List.fromList(<int>[1, 2, 3, 4]),
        ]);

        final result = await manager.compute(
          <String, Object?>{'packet': packet},
          transferables: <Object>[packet],
        );

        expect(result['sum'], 10);

        await manager.stop();
      },
    );
  });
}
