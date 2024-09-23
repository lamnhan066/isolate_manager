import 'dart:collection';

import 'package:isolate_manager/src/models/isolate_queue.dart';

/// Strategy to control a new (incoming) computation if the maximum number of Queues
/// is reached.
///
/// Some of strategies:
///   - [IsolateQueueStrategyRemoveNewest] is default.
///   - [IsolateQueueStrategyRemoveOldest]
///   - [IsolateQueueStrategyDiscardIncoming]
abstract class IsolateQueueStrategy<R, P> {
  /// Queue of isolates.
  final Queue<IsolateQueue<R, P>> _queues = Queue();

  /// Max number of queued computations.
  ///
  /// If this value <= 0, the number of queues is unlimited (default).
  final int maxCount;

  /// Number of the current queues.
  int get queuesCount => _queues.length;

  /// Strategy to control a new (incoming) computation if the maximum number of Queues
  /// is reached. The maximum number is unlimited if [maxCount] <= 0 (by default).
  ///
  /// Some of strategies:
  ///   - [IsolateQueueStrategyRemoveNewest] is default.
  ///   - [IsolateQueueStrategyRemoveOldest]
  ///   - [IsolateQueueStrategyDiscardIncoming]
  IsolateQueueStrategy({this.maxCount = 0});

  /// Run this method before adding a new computation to the Queue if the max
  /// queue count is exceeded. If this method returns `false`, the new computation
  /// will not be added to the Queue.
  bool continueIfMaxCountExceeded();

  /// Add a new computation to the Queue.
  ///
  /// If [addToTop] is `true`, the new computation will be added to the top of the
  /// Queue.
  void add(IsolateQueue<R, P> queue, {bool addToTop = false}) {
    if (maxCount > 0 && queuesCount >= maxCount) {
      if (!continueIfMaxCountExceeded()) return;
    }
    if (addToTop) {
      _queues.addFirst(queue);
    } else {
      _queues.add(queue);
    }
  }

  /// Check if the Queue is not empty.
  bool hasNext() {
    return _queues.isNotEmpty;
  }

  /// Get the next computation.
  IsolateQueue<R, P> getNext() {
    assert(hasNext());
    return _queues.removeFirst();
  }

  /// Clear all queues.
  void clear() => _queues.clear();
}

class IsolateQueueStrategyRemoveNewest<R, P>
    extends IsolateQueueStrategy<R, P> {
  /// Remove the newest computation if the [maxCount] is exceeded.
  IsolateQueueStrategyRemoveNewest({super.maxCount = 0});

  @override
  bool continueIfMaxCountExceeded() {
    // Remove the last computation if the Queue (mean the newest one).
    _queues.removeLast();
    // It means the current computation should be added to the Queue.
    return true;
  }
}

class IsolateQueueStrategyRemoveOldest<R, P>
    extends IsolateQueueStrategy<R, P> {
  /// Remove the oldest computation if the [maxCount] is exceeded.
  IsolateQueueStrategyRemoveOldest({super.maxCount = 0});

  @override
  bool continueIfMaxCountExceeded() {
    // Remove the first computation if the Queue (mean the oldest one).
    _queues.removeFirst();
    // It means the current computation should be added to the Queue.
    return true;
  }
}

class IsolateQueueStrategyDiscardIncoming<R, P>
    extends IsolateQueueStrategy<R, P> {
  /// Discard the new incoming computation if the [maxCount] is exceeded.
  IsolateQueueStrategyDiscardIncoming({
    super.maxCount = 0,
  });

  @override
  bool continueIfMaxCountExceeded() {
    // It means the current computation should NOT be added to the Queue.
    return false;
  }
}
