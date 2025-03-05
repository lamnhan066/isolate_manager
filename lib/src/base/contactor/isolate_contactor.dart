import 'dart:async';

import 'package:isolate_manager/src/base/contactor/isolate_contactor/isolate_contactor_web.dart'
    if (dart.library.io) 'isolate_contactor/isolate_contactor_stub.dart';
import 'package:isolate_manager/src/utils/converter.dart';
import 'package:isolate_manager/src/utils/print.dart';

/// The type of the `function` of the `.create` method.
typedef IsolateFunction<R, P> = FutureOr<R> Function(P params);

/// The type of the `function` of the `.createCustom` method.
typedef IsolateCustomFunction = FutureOr<void> Function(dynamic);

/// The type of the `function` of the `.createCustom` method.
@Deprecated('Use `IsolateCustomFunction` instead')
typedef CustomIsolateFunction = IsolateCustomFunction;

/// The type of the `converter` and `workerConverter`.
typedef IsolateConverter<R> = R Function(dynamic value);

/// This [IsolateContactor] needs [P] as an input param type and [R]
/// as a return type.
abstract class IsolateContactor<R, P> {
  /// Constructer.
  const IsolateContactor({this.debugMode = false});

  /// Use this value to change the prefix debug log.
  ///
  /// Ex: 'Isolate Contactor' => [Isolate Contactor]: there is log.
  static String debugLogPrefix = 'Isolate Contactor';

  /// Debug mode.
  final bool debugMode;

  /// Create an instance with your custom isolate function.
  ///
  /// `function` is You can take a look at the example to see what you need
  /// to do to make it works.
  ///
  /// `workerName` name of the function, also name of thing like
  /// `functionName.dart.js` on Web platform. If this value is not specified,
  /// the plugin will use `Future` instead of `Worker`.
  ///
  /// `converter` (for Native) convert result before sending to to the result.
  ///
  /// `workerConverter` (for Worker on Web) convert result before sending to to
  /// the result.
  ///
  /// `isolateParams` is the list of parameters that you want to add to your
  /// [function]
  ///
  /// `debugMode` allow printing debug data in console. Default is set to false.
  static Future<IsolateContactor<R, P>> createCustom<R, P>(
    IsolateCustomFunction function, {
    String workerName = '',
    IsolateConverter<R>? converter,
    IsolateConverter<R>? workerConverter,
    Object? initialParams,
    bool debugMode = false,
  }) async {
    return IsolateContactorInternal.createCustom<R, P>(
      isolateFunction: function,
      workerName: workerName,
      converter: (value) => converterHelper(value, converter),
      workerConverter: (value) => converterHelper(value, workerConverter),
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
    debugPrinter(object, debug: debugMode);
  }
}
