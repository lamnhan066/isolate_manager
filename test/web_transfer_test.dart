@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:test/test.dart';

import 'functions.dart';

const bool _isWasm = bool.fromEnvironment('dart.tool.dart2wasm');

void main() {
  IsolateManager.addWorkerMapping(processBytes, 'workers/processBytes');

  group('Web ArrayBuffer Transfer', () {
    test('should transfer large Uint8List with zero-copy', () async {
      final manager = IsolateManager.create(
        processBytes,
        workerName: 'workers/processBytes',
      );

      await manager.start();

      final largeData = Uint8List(1024 * 1024); // 1MB
      for (var i = 0; i < largeData.length; i++) {
        largeData[i] = i % 256;
      }

      final originalLength = largeData.buffer.lengthInBytes;

      // Pass transferables explicitly through compute()
      final result = await manager.compute(
        largeData,
        transferables: [largeData.buffer],
      );

      expect(result.length, originalLength);

      // Verify the processing worked
      for (var i = 0; i < min(100, result.length); i++) {
        expect(result[i], (i + 1) % 256);
      }

      // After transfer, the source buffer should be detached (zero-length)
      if (_isWasm) {
        expect(
          largeData.buffer.lengthInBytes,
          originalLength,
          reason:
              'WASM currently does not detach the source buffer after transfer list send.',
        );
      } else {
        expect(
          largeData.buffer.lengthInBytes,
          0,
          reason: 'Source buffer should be detached after zero-copy transfer',
        );
      }

      await manager.stop();
    });

    test('should work without transferables (copy mode)', () async {
      final manager = IsolateManager.create(
        processBytes,
        workerName: 'workers/processBytes',
      );

      await manager.start();

      final data = Uint8List(1024);
      for (var i = 0; i < data.length; i++) {
        data[i] = i % 256;
      }

      // No transferables — data is copied
      final result = await manager.compute(data);

      expect(result.length, data.length);
      for (var i = 0; i < min(100, result.length); i++) {
        expect(result[i], (i + 1) % 256);
      }

      // Source buffer remains intact when not using transferables
      expect(data.buffer.lengthInBytes, 1024);

      await manager.stop();
    });

    test('ByteBuffer can be extracted to JSArrayBuffer', () {
      final bytes = Uint8List(100);
      final buffer = bytes.buffer;

      // Verify we can get the buffer
      expect(buffer.lengthInBytes, 100);

      // This simulates what our extractArrayBuffers does
      expect(buffer, isA<ByteBuffer>());
    });

    test('should accept JSArrayBuffer in transferables list', () async {
      final manager = IsolateManager.create(
        processBytes,
        workerName: 'workers/processBytes',
      );

      await manager.start();

      final data = Uint8List(2048);
      for (var i = 0; i < data.length; i++) {
        data[i] = i % 256;
      }

      final result = await manager.compute(
        data,
        transferables: <Object>[data.buffer.toJS],
      );

      expect(result.length, data.length);
      await manager.stop();
    });
  });
}
