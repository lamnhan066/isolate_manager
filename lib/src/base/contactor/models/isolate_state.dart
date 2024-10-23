/// Isolate state
enum IsolateState {
  /// A dispose state
  dispose,

  /// An initialized state
  initialized;

  /// {
  ///   type: '$IsolateState',
  ///   value: [name],
  /// }
  Map<String, String> toMap() =>
      <String, String>{'type': r'$IsolateState', 'value': name};

  /// Check if the [map] is a valid enum.
  bool isValidMap(Map<dynamic, dynamic> map) {
    return map.containsKey('type') &&
        map['type'] == r'$IsolateState' &&
        map['value'] == name;
  }
}
