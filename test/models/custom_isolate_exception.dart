import 'package:isolate_manager/isolate_manager.dart';

class CustomIsolateException extends IsolateException {
  const CustomIsolateException(super.error);

  @override
  String get name => 'CustomIsolateException';
}
