import 'dart:collection';

import 'package:isolate_manager/src/models/isolate_queue.dart';

/// Strategy to control a new (incoming) computation if the maximum number of Queues
/// is reached.
///
/// Some of strategies:
///   - [QueueStrategyUnlimited] - is default.
///   - [QueueStrategyRemoveNewest]
///   - [QueueStrategyRemoveOldest]
///   - [QueueStrategyDiscardIncoming]
abstract class QueueStrategy<R, P> {
  /// Queue of isolates.
  final Queue<IsolateQueue<R, P>> queues = Queue();

  /// Max number of queued computations.
  ///
  /// If this value <= 0, the number of queues is unlimited (default).
  final int maxCount;

  /// Number of the current queues.
  int get queuesCount => queues.length;

  /// Strategy to control a new (incoming) computation if the maximum number of Queues
  /// is reached. The maximum number is unlimited if [maxCount] <= 0 (by default).
  ///
  /// Some of strategies:
  ///   - [QueueStrategyUnlimited] is default.
  ///   - [QueueStrategyRemoveNewest]
  ///   - [QueueStrategyRemoveOldest]
  ///   - [QueueStrategyDiscardIncoming]
  QueueStrategy({this.maxCount = 0});

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
      queues.addFirst(queue);
    } else {
      queues.add(queue);
    }
  }

  /// Check if the Queue is not empty.
  bool hasNext() {
    return queues.isNotEmpty;
  }

  /// Get the next computation.
  IsolateQueue<R, P> getNext() {
    assert(hasNext());
    return queues.removeFirst();
  }

  /// Clear all queues.
  void clear() => queues.clear();
}

class QueueStrategyUnlimited<R, P> extends QueueStrategy<R, P> {
  /// Unlimited queued computations.
  QueueStrategyUnlimited();

  @override
  bool continueIfMaxCountExceeded() => true;
}

class QueueStrategyRemoveNewest<R, P> extends QueueStrategy<R, P> {
  /// Remove the newest computation if the [maxCount] is exceeded.
  QueueStrategyRemoveNewest({super.maxCount = 0});

  @override
  bool continueIfMaxCountExceeded() {
    // Remove the last computation if the Queue (mean the newest one).
    queues.removeLast();
    // It means the current computation should be added to the Queue.
    return true;
  }
}

class QueueStrategyRemoveOldest<R, P> extends QueueStrategy<R, P> {
  /// Remove the oldest computation if the [maxCount] is exceeded.
  QueueStrategyRemoveOldest({super.maxCount = 0});

  @override
  bool continueIfMaxCountExceeded() {
    // Remove the first computation if the Queue (mean the oldest one).
    queues.removeFirst();
    // It means the current computation should be added to the Queue.
    return true;
  }
}

class QueueStrategyDiscardIncoming<R, P> extends QueueStrategy<R, P> {
  /// Discard the new incoming computation if the [maxCount] is exceeded.
  QueueStrategyDiscardIncoming({
    super.maxCount = 0,
  });

  @override
  bool continueIfMaxCountExceeded() {
    // It means the current computation should NOT be added to the Queue.
    return false;
  }
}
