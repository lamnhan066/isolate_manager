import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager_example/functions.dart';

/// dart compile js fibonacci_rescusive.dart -o fibonacci_rescusive.js -O4

main() {
  isolateWorker(fibonacciRescusiveFuture);
}
