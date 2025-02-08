import 'dart:async';

import 'package:isolate_manager/src/isolate_manager.dart';

/// Use for queuing your `compute`.
class IsolateQueue<R, P> {
  /// Use for queuing your `compute`.
  IsolateQueue(this.params, IsolateCallback<R>? callback)
      : callback = callback ?? _defaultCallback<R>;

  /// A default callback.
  static bool _defaultCallback<R>(R _) => true;

  /// Control the state and result of this `IsolateQueue`.
  final Completer<R> completer = Completer<R>();

  /// Control the params of this `IsolateQueue`.
  final P params;

  /// Control when to return the needed result.
  final IsolateCallback<R> callback;
}
