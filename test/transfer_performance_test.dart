// For debug only
// ignore_for_file: avoid_print, document_ignores

@TestOn('vm')
library;

import 'dart:isolate';
import 'dart:typed_data';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:test/test.dart';

import 'benchmark_helpers.dart';
import 'functions.dart';

// Worker that accepts a Map containing a pre-built TransferableTypedData
// and echoes back the materialized bytes. Used to benchmark the minimum
// possible channel cost when the caller has already done the fromList() copy.
@pragma('vm:entry-point')
void _ttdEchoWorker(dynamic params) {
  final controller = IsolateManagerController<Uint8List, Map<String, Object?>>(
    params,
  );
  controller.onIsolateMessage.listen((message) {
    final packet = message['packet']! as TransferableTypedData;
    controller.sendResult(Uint8List.view(packet.materialize()));
  });
  controller.initialized();
}

void main() {
  group('Transfer Performance (VM)', () {
    late IsolateManager<Uint8List, Uint8List> manager;
    late IsolateManager<Uint8List, Map<String, Object?>> ttdManager;

    setUpAll(() async {
      manager = IsolateManager.create(identityBytes);
      ttdManager = IsolateManager.createCustom(_ttdEchoWorker);
      await manager.start();
      await ttdManager.start();
    });

    tearDownAll(() async {
      await manager.stop();
      await ttdManager.stop();
    });

    for (final sizeKb in benchmarkSizesKb) {
      test('transport benchmark ${sizeKb}KB', () async {
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
        final packets = List<TransferableTypedData>.generate(
          config.totalRuns,
          (_) => TransferableTypedData.fromList([buildBytes(bytesLength)]),
        );

        final transportWithByteBuffer = await runBenchmarkCase(
          warmups: config.warmups,
          runs: config.runs,
          body: (index) async {
            final data = transportDataWithTransfer[index];
            final result = await manager.compute(
              data,
              transferables: <Object>[data.buffer],
            );
            expect(result.length, bytesLength);
          },
        );

        final transportWithoutTransferables = await runBenchmarkCase(
          warmups: config.warmups,
          runs: config.runs,
          body: (index) async {
            final data = transportDataWithoutTransfer[index];
            final result = await manager.compute(data);
            expect(result.length, bytesLength);
          },
        );

        final transportWithPrebuiltTtd = await runBenchmarkCase(
          warmups: config.warmups,
          runs: config.runs,
          body: (index) async {
            final packet = packets[index];
            final result = await ttdManager.compute(
              <String, Object?>{'packet': packet},
              transferables: <Object>[packet],
            );
            expect(result.length, bytesLength);
          },
        );

        print('');
        print('  ${sizeKb}KB (warmup=${config.warmups}, runs=${config.runs})');
        print(
          '    transport_with_ByteBuffer: ${formatMs(transportWithByteBuffer)}',
        );
        print(
          '    transport_without_transferables: '
          '${formatMs(transportWithoutTransferables)}',
        );
        print(
          '    transport_with_prebuilt_TTD: ${formatMs(transportWithPrebuiltTtd)}',
        );
      });
    }
  });
}
