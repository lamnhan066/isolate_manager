import 'dart:async';

class IsolateQueue<R> {
  final Completer<R> completer = Completer<R>();
  final dynamic params;

  IsolateQueue(this.params);
}
