library isolate_manager;

export 'package:isolate_contactor/isolate_contactor.dart' show IsolateException;

export 'src/isolate_manager.dart';
export 'src/isolate_manager_controller.dart';
export 'src/isolate_worker/isolate_worker_web.dart'
    if (dart.library.io) 'src/isolate_worker/isolate_worker_stub.dart';
