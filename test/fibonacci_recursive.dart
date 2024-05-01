import 'package:isolate_manager/isolate_manager.dart';

import 'isolate_manager_test.dart';

/// dart compile js fibonacci_recursive.dart -o fibonacci_recursive.js -O4

main() {
  IsolateManagerFunction.workerFunction(fibonacciRecursive);
}
