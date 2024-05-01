// coverage:ignore-file
// Tested by compiling to `js` for the Web Worker.

import 'dart:async';

import 'isolate_worker_web.dart'
    if (dart.library.io) 'isolate_worker_stub.dart';

/// A function for the `IsolateManagerFunction.workerFunction`.
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
/// When you're using the [onInitial], you have to set the `autoInitialize` parameter
/// of the `create` and `createCustom` to `false`. Without it, the `Worker` will
/// be stucked forever.
///
/// If you need to throw an exception, you should only throw the `message`
/// instead of a whole Object because it may not be shown as expected when
/// sending back to the main app.
///
/// ``` dart
///  return throw 'This is an error that you need to catch in your main app';
/// ```
@Deprecated('Use `IsolateManagerFunction.workerFunction` instead')
Future<void> isolateWorker<R, P>(
  IsolateWorkerFunction<R, P> function, {
  FutureOr<void> Function()? onInitial,
}) {
  return isolateWorkerImpl<R, P>(function, onInitial);
}
