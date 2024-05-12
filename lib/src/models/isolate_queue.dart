import 'dart:async';

import 'package:isolate_manager/src/isolate_manager.dart';

/// Use for queuing your `compute`.
class IsolateQueue<R, P> {
  /// Control the state and result of this `IsolateQueue`.
  final Completer<R> completer = Completer<R>();

  /// Control the params of this `IsolateQueue`.
  final P params;

  /// Control when to return the needed result.
  final IsolateCallback<R>? callback;

  /// Use for queuing your `compute`.
  IsolateQueue(this.params, this.callback);
}
