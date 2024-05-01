import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager_example/functions.dart';

/// dart compile js complex.dart -o complex.js -O4

main() {
  IsolateManagerFunction.workerFunction(complexFunction);
}
