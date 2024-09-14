/// The priority of a `compute`.
///
/// If multiple functions have the same priority, the oldest one will be
/// executed first (FIFO).
enum IsolatePriority {
  /// High priority
  high,

  /// Medium priority (default).
  medium,

  /// Low priority.
  low
}
