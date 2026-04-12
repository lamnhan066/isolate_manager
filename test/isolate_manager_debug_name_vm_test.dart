@TestOn('vm')
library;

import 'dart:async';
import 'dart:isolate';

import 'package:isolate_manager/isolate_manager.dart';
import 'package:test/test.dart';

@pragma('vm:entry-point')
Future<String?> reportCurrentIsolateDebugName(int delayMilliseconds) async {
  if (delayMilliseconds > 0) {
    await Future<void>.delayed(Duration(milliseconds: delayMilliseconds));
  }

  return Isolate.current.debugName;
}

void main() {
  group('Isolate debugName', () {
    test('uses a default isolate name when debugName is omitted', () async {
      final manager = IsolateManager<String?, int>.create(
        reportCurrentIsolateDebugName,
      );

      final debugName = await manager.compute(0);

      expect(debugName, isNotNull);
      expect(debugName, matches(RegExp(r'^Isolate-\d+$')));

      await manager.stop();
    });

    test(
      'adds a group name and per-isolate index for shared managers',
      () async {
        final manager = IsolateManager.createShared(
          concurrent: 2,
          debugName: 'worker',
        );

        final debugNames = await Future.wait<String?>([
          manager.compute(reportCurrentIsolateDebugName, 30),
          manager.compute(reportCurrentIsolateDebugName, 30),
        ]);

        expect(debugNames, hasLength(2));
        expect(debugNames.toSet(), hasLength(2));
        expect(debugNames[0], isNotNull);
        expect(debugNames[1], isNotNull);
        expect(debugNames[0], matches(RegExp(r'^Isolate-\d+-worker-[12]$')));
        expect(debugNames[1], matches(RegExp(r'^Isolate-\d+-worker-[12]$')));
        expect(
          debugNames.any((name) => name?.endsWith('-worker-1') ?? false),
          isTrue,
        );
        expect(
          debugNames.any((name) => name?.endsWith('-worker-2') ?? false),
          isTrue,
        );

        await manager.stop();
      },
    );

    test('keeps global isolate names unique across managers', () async {
      final workerManager = IsolateManager<String?, int>.create(
        reportCurrentIsolateDebugName,
        debugName: 'worker',
      );
      final processorManager = IsolateManager<String?, int>.create(
        reportCurrentIsolateDebugName,
        debugName: 'processor',
      );

      final workerDebugName = await workerManager.compute(0);
      final processorDebugName = await processorManager.compute(0);

      expect(workerDebugName, matches(RegExp(r'^Isolate-\d+-worker-1$')));
      expect(
        processorDebugName,
        matches(RegExp(r'^Isolate-\d+-processor-1$')),
      );
      expect(workerDebugName, isNot(equals(processorDebugName)));

      await workerManager.stop();
      await processorManager.stop();
    });
  });
}
