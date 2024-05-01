import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager_example/functions.dart';

/// dart compile js fibonacci_recursive.dart -o fibonacci_recursive.js -O4

main() {
  IsolateManagerFunction.workerFunction(fibonacciRecursiveFuture);
}
