import 'package:isolate_manager/isolate_manager.dart';
import 'package:isolate_manager_example/functions.dart';

/// dart compile js function_name.dart -o function_name.js -O4

void main(List<String> args) {
  isolateWorker(functionName);
}
