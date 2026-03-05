import 'dart:typed_data';

const benchmarkSizesKb = <int>[100, 1024, 10240];

({int warmups, int runs, int totalRuns}) benchmarkConfigForSize(int sizeKb) {
  if (sizeKb >= 10240) return (warmups: 1, runs: 2, totalRuns: 3);
  if (sizeKb >= 1024) return (warmups: 1, runs: 3, totalRuns: 4);
  return (warmups: 2, runs: 5, totalRuns: 7);
}

Future<double> runBenchmarkCase({
  required int warmups,
  required int runs,
  required Future<void> Function(int index) body,
}) async {
  final total = warmups + runs;

  for (var i = 0; i < warmups; i++) {
    await body(i);
  }

  final samplesMicros = <int>[];
  for (var i = warmups; i < total; i++) {
    final sw = Stopwatch()..start();
    await body(i);
    sw.stop();
    samplesMicros.add(sw.elapsedMicroseconds);
  }

  return _medianMicrosToMs(samplesMicros);
}

String formatMs(double ms) => '${ms.toStringAsFixed(2)}ms';

Uint8List buildBytes(int length) {
  final bytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    bytes[i] = i % 256;
  }
  return bytes;
}

double _medianMicrosToMs(List<int> values) {
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) {
    return sorted[middle] / 1000.0;
  }
  return (sorted[middle - 1] + sorted[middle]) / 2000.0;
}
