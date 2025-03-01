import 'dart:async';

import 'package:isolate_manager/src/base/contactor/isolate_contactor.dart';
import 'package:isolate_manager/src/base/contactor/isolate_contactor_controller.dart';
import 'package:isolate_manager/src/base/contactor/isolate_contactor_controller/web_platform/isolate_contactor_controller_web.dart';
import 'package:isolate_manager/src/base/contactor/isolate_contactor_controller/web_platform/isolate_contactor_controller_web_worker.dart';
import 'package:isolate_manager/src/base/contactor/models/isolate_contactor_controller_web_controller_mixin.dart';

/// Implementation of the [IsolateContactorController] in `web`.
abstract class IsolateContactorControllerImpl<R, P>
    with IsolateContactorControllerWebControllerMixin
    implements IsolateContactorController<R, P> {
  /// Implementation of the [IsolateContactorController] in `web`.
  factory IsolateContactorControllerImpl(
    dynamic params, {
    required void Function()? onDispose,
    required IsolateConverter<R> converter, // Converter for native
    required IsolateConverter<R>
        workerConverter, // Converter for Worker (Web Only)
    required bool debugMode,
  }) {
    if (params is StreamController ||
        params is List &&
            (params.last as IsolateContactorControllerImpl).controller
                is StreamController) {
      return IsolateContactorControllerImplFuture<R, P>(
        params,
        onDispose: onDispose,
        converter: converter,
        debugMode: debugMode,
      );
    }

    return IsolateContactorControllerImplWorker<R, P>(
      params,
      onDispose: onDispose,
      workerConverter: workerConverter,
      debugMode: debugMode,
    );
  }
}
