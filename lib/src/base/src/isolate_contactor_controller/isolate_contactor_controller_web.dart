import 'dart:async';

import 'package:isolate_manager/src/base/src/models/isolate_contactor_controller_web_controller_mixin.dart';

import '../isolate_contactor.dart';
import '../isolate_contactor_controller.dart';
import 'web_platform/isolate_contactor_controller_web.dart';
import 'web_platform/isolate_contactor_controller_web_worker.dart';

abstract class IsolateContactorControllerImpl<R, P>
    with IsolateContactorControllerWebControllerMixin
    implements IsolateContactorController<R, P> {
  factory IsolateContactorControllerImpl(
    dynamic params, {
    required void Function()? onDispose,
    required IsolateConverter<R> converter, // Converter for native
    required IsolateConverter<R>
        workerConverter, // Converter for Worker (Web Only)
  }) {
    if (params is StreamController ||
        params is List && params.last.controller is StreamController) {
      return IsolateContactorControllerImplFuture<R, P>(
        params,
        onDispose: onDispose,
        converter: converter,
        workerConverter: workerConverter,
      );
    }

    return IsolateContactorControllerImplWorker<R, P>(
      params,
      onDispose: onDispose,
      converter: converter,
      workerConverter: workerConverter,
    );
  }
}
