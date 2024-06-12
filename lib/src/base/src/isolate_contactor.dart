import 'dart:async';

import 'isolate_contactor/isolate_contactor_web.dart'
    if (dart.library.io) 'isolate_contactor/isolate_contactor_stub.dart';

/// The type of the `function` of the `.create` method.
typedef IsolateFunction<R, P> = FutureOr<R> Function(P params);

/// The type of the `function` of the `.createCustom` method.
typedef CustomIsolateFunction = FutureOr<void> Function(dynamic);

/// The type of the `converter` and `workerConverter`.
typedef IsolateConverter<R> = R Function(dynamic);

/// This [IsolateContactor] needs [P] as an input param type and [R] as a return type.
abstract class IsolateContactor<R, P> {
  /// Use this value to change the prefix debug log.
  ///
  /// Ex: 'Isolate Contactor' => [Isolate Contactor]: there is log.
  static String debugLogPrefix = 'Isolate Contactor';

  /// Debug mode.
  final bool debugMode;

  /// Constructer.
  const IsolateContactor(this.debugMode);

  /// Create an instance with your custom isolate function.
  ///
  /// `function` is You can take a look at the example to see what you need to do
  /// to make it works.
  ///
  /// `workerName` name of the function, also name of thing like `functionName.dart.js` on Web platform.
  /// If this value is not specified, the plugin will use `Future` instead of `Worker`.
  ///
  /// `converter` (for Native) convert result before sending to to the result.
  ///
  /// `workerConverter` (for Worker on Web) convert result before sending to to the result.
  ///
  /// `isolateParams` is the list of parameters that you want to add to your [function]
  ///
  /// `debugMode` allow printing debug data in console. Default is set to false.
  static Future<IsolateContactor<R, P>> createCustom<R, P>(
    /// `function` You can take a look at the example to see what you need to do
    /// to make it works.
    CustomIsolateFunction function, {
    /// `workerName` name of the function, also name of thing like `functionName.dart.js` on Web platform.
    /// If this value is not specified, the plugin will use `Future` instead of `Worker`.
    String workerName = '',

    /// `converter` (for Native) convert result before sending to to the result.
    IsolateConverter<R>? converter,

    /// `workerConverter` (for Worker on Web) convert result before sending to to the result.
    IsolateConverter<R>? workerConverter,

    /// `isolateParams` is the list of parameters that you want to add to your [function]
    /// `debugMode` allow printing debug data in console. Default is set to false.
    Object? initialParams,

    /// `debugMode` allow printing debug data in console. Default is set to false.
    bool debugMode = false,
  }) async {
    // The `workerConverter` is not covered when running `flutter test --coverage`
    // so this is just a hack to make it covered.
    R tempConverter(dynamic value) => value as R;
    converter ??= tempConverter;
    workerConverter ??= tempConverter;
    return IsolateContactorInternal.createCustom<R, P>(
      isolateFunction: function,
      workerName: workerName,
      converter: converter,
      workerConverter: workerConverter,
      initialParams: initialParams,
      debugMode: debugMode,
    );
  }

  /// Send message to the `function` for computing
  ///
  /// Throw `IsolateContactorException` when error occurs.
  Future<R> sendMessage(P message);

  /// Listen to the result from the isolate.
  Stream<R> get onMessage;

  /// Dispose current isolate
  Future<void> dispose();

  /// Print if [debugMode] is true
  void printDebug(Object? Function() object) {
    if (debugMode) {
      print('[${IsolateContactor.debugLogPrefix}]: ${object()}');
    }
  }
}
