/// Create multiple long-lived isolates for a function (keep it active to send
/// and receive data), supports Worker and WASM on the Web.
library;

export 'src/base/isolate_contactor.dart'
    show IsolateConverter, IsolateException, IsolateFunction, IsolateState;
export 'src/base/isolate_manager_shared.dart';
export 'src/isolate_manager.dart';
export 'src/isolate_manager_function.dart';
export 'src/models/isolate_exceptions.dart';
export 'src/models/isolate_manager_custom_worker.dart';
export 'src/models/isolate_manager_shared_worker.dart';
export 'src/models/isolate_manager_worker.dart';
export 'src/models/isolate_types.dart';
export 'src/models/queue_strategy.dart';
