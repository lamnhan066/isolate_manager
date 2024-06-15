import 'package:isolate_manager/src/isolate_manager_function.dart';

import 'isolate_manager_test.dart';

void main() {
  IsolateManagerFunction.customWorkerFunction(isolateCallbackFunction);
}
