import 'package:isolate_manager/isolate_manager.dart';

import '../functions.dart';

/// dart compile js fibonacci.dart -o fibonacci.js -O4

main() {
  IsolateManagerFunction.workerFunction(fibonacci);
}
