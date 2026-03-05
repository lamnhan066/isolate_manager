// For debug only
// ignore_for_file: avoid_print, document_ignores

@TestOn('chrome')
library;

import 'dart:typed_data';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:test/test.dart';

import 'benchmark_helpers.dart';
import 'functions.dart';

const bool _isWasm = bool.fromEnvironment('dart.tool.dart2wasm');

void main() {
  IsolateManager.addWorkerMapping(identityBytes, 'workers/identityBytes');

  group('Web Transfer Performance (Worker)', () {
    late IsolateManager<Uint8List, Uint8List> manager;

    setUp(() async {
      manager = IsolateManager.create(
        identityBytes,
        workerName: 'workers/identityBytes',
      );
      await manager.start();
    });

    tearDown(() async {
      await manager.stop();
    });

    for (final sizeKb in benchmarkSizesKb) {
      test('transport benchmark ${sizeKb}KB', () async {
        // dart2wasm offers no transfer benefit at 10MB+ and the pre-allocation
        // cost (60MB byte-by-byte fill in WASM) causes CI timeout.
        if (_isWasm && sizeKb >= 10240) {
          return;
        }

        final config = benchmarkConfigForSize(sizeKb);
        final bytesLength = sizeKb * 1024;

        final transportDataWithTransfer = List<Uint8List>.generate(
          config.totalRuns,
          (_) => buildBytes(bytesLength),
        );
        final transportDataWithoutTransfer = List<Uint8List>.generate(
          config.totalRuns,
          (_) => buildBytes(bytesLength),
        );

        final transportWith = await runBenchmarkCase(
          warmups: config.warmups,
          runs: config.runs,
          body: (index) async {
            final data = transportDataWithTransfer[index];
            final originalLength = data.buffer.lengthInBytes;
            final result = await manager.compute(
              data,
              transferables: <Object>[data.buffer],
            );
            expect(result.length, bytesLength);
            _expectTransferState(
              data: data,
              originalLength: originalLength,
              expectDetached: !_isWasm,
            );
          },
        );

        final transportWithout = await runBenchmarkCase(
          warmups: config.warmups,
          runs: config.runs,
          body: (index) async {
            final data = transportDataWithoutTransfer[index];
            final result = await manager.compute(data);
            expect(result.length, bytesLength);
            expect(data.buffer.lengthInBytes, bytesLength);
          },
        );

        print('');
        print('  ${sizeKb}KB (warmup=${config.warmups}, runs=${config.runs})');
        print(
          '    transport_with_prebuilt_transferables: '
          '${formatMs(transportWith)}',
        );
        print(
          '    transport_without_prebuilt_transferables: ${formatMs(transportWithout)}',
        );
      });
    }
  });
}

void _expectTransferState({
  required Uint8List data,
  required int originalLength,
  required bool expectDetached,
}) {
  if (expectDetached) {
    expect(
      data.buffer.lengthInBytes,
      0,
      reason: 'Source buffer should be detached after transfer list send.',
    );
  } else {
    expect(
      data.buffer.lengthInBytes,
      originalLength,
      reason:
          'WASM currently does not detach the source buffer after transfer list send.',
    );
  }
}
