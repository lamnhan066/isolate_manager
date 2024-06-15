import '../base/isolate_manager_shared.dart';

/// All functions with this annotation will be combined and generated to the `$shared_worker.js`
/// inside the `web` folder.
const isolateManagerSharedWorker =
    _IsolateManagerWorkerShared(kSharedWorkerName);

/// Shared Worker annotation
class _IsolateManagerWorkerShared {
  /// Name of the Worker JS. Default is `worker.js`.
  final String name;
  const _IsolateManagerWorkerShared([this.name = kSharedWorkerName]);
}
