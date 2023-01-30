import 'dart:async';

/// Use for queuing your `compute`
class IsolateQueue<R> {
  /// Control the state and result of this `IsolateQueue`
  final Completer<R> completer = Completer<R>();

  /// Control the params of this `IsolateQueue`
  final dynamic params;

  /// Use for queuing your `compute`
  IsolateQueue(this.params);
}
