import 'package:isolate_contactor/isolate_contactor.dart';

class IsolateManagerController<T> implements IsolateContactorController<T> {
  late IsolateContactorController<T> _delegate;

  IsolateManagerController(
    dynamic params, {
    Function()? onDispose,
    T Function(dynamic)? converter,
    T Function(dynamic)? workerConverter,
  }) {
    _delegate = IsolateContactorController(
      params,
      onDispose: onDispose,
      converter: converter,
      workerConverter: workerConverter,
    );
  }

  @override
  Future<void> close() => _delegate.close();

  @override
  get controller => _delegate.controller;

  @override
  get initialParams => _delegate.initialParams;

  @override
  Stream get onIsolateMessage => _delegate.onIsolateMessage;

  @override
  Stream<T> get onMessage => _delegate.onMessage;

  @override
  void sendIsolate(message) => _delegate.sendIsolate(message);

  @override
  void sendResult(T result) => _delegate.sendResult(result);
}
