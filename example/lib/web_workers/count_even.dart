import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager_example/functions.dart';

/// dart compile js count_even.dart -o count_even.js -O4

void main(List<String> args) {
  IsolateManagerFunction.workerFunction(countEven);
}
