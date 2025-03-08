import 'package:isolate_manager/isolate_manager.dart';

@isolateManagerWorker
int fibonacciRecursive(int n) {
  if (n == 0) return 0;
  if (n == 1) return 1;
  return fibonacciRecursive(n - 1) + fibonacciRecursive(n - 2);
}
