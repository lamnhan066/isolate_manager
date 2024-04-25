import 'dart:async';

import 'isolate_worker_web.dart'
    if (dart.library.io) 'isolate_worker_stub.dart';

/// A function for the [isolateWorker].
typedef IsolateWorkerFunction<R, P> = FutureOr<R> Function(P message);

/// Create a worker in your `main`.
///
/// ```dart
/// main() {
///   isolateWorker(myFunction);
/// }
/// ```
///
/// Build it with `dart compile js worker.dart -o worker.js -O4` and copy the `worker.js` to
/// your Web folder.
///
/// If you need to throw an exception, you should only throw the `message`
/// instead of a whole Object because it may not be shown as expected when
/// sending back to the main app.
///
/// ``` dart
///  return throw 'This is an error that you need to catch in your main app';
/// ```
@Deprecated('Use `IsolateFunction.workerFunction` instead')
void isolateWorker<R, P>(IsolateWorkerFunction<R, P> function) {
  return isolateWorkerImpl<R, P>(function);
}
