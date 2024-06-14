import 'dart:convert';

/// Isolate state
enum IsolateState {
  /// A dispose state
  dispose,

  /// An initialized state
  initialized;

  /// {
  ///   type: '$IsolateState',
  ///   value: '<name>',
  /// }
  String toJson() => jsonEncode({'type': r'$IsolateState', 'value': name});

  /// Check if the [object] is a valid enum.
  bool isValidJson(Object? object) {
    try {
      final decoded = jsonDecode(object.toString()) as Map;
      return decoded['type'] == r'$IsolateState' && decoded['value'] == name;
    } catch (_) {}
    return false;
  }
}
