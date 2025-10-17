// Reason: ImType and its subclasses require custom equality logic for isolate-safe value comparison.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:isolate_manager/src/models/isolate_exceptions.dart';

/// An abstract wrapper for simple transferable types between the main thread
/// and worker isolates.
///
/// Use this class as the parameter or return type in your isolate communication
/// methods. It provides safe wrapping for these non-nullable Dart types:
///   - [num] (wrapped in [ImNum])
///   - [String] (wrapped in [ImString])
///   - [bool] (wrapped in [ImBool])
///   - [List] (wrapped in [ImList])
///   - [Map] (wrapped in [ImMap])
///
/// The static [wrap] method wraps a Dart object in the appropriate [ImType].
sealed class ImType<T extends Object> {
  /// Creates an instance of [ImType] holding the provided [_value].
  const ImType(this._value);

  /// Converts a plain Dart object into its corresponding [ImType] instance.
  ///
  /// Supported types include these non-nullable Dart types:
  ///   [num], [String], [bool], [List], and [Map] that contain these types.
  ///
  /// Throws an [UnsupportedImTypeException] if the object's type is not supported.
  static R wrap<R extends ImType<Object>>(Object? object) {
    return switch (object) {
          final R r => r,
          final num n => ImNum(n),
          final String s => ImString(s),
          final bool b => ImBool(b),
          final Iterable<dynamic> list => ImList(
            list.map((e) => wrap(e as Object?)),
          ),
          final Map<dynamic, dynamic> map => ImMap(
            map.map((k, v) => MapEntry(wrap(k as Object?), wrap(v as Object?))),
          ),
          _ =>
            throw UnsupportedImTypeException(
              'Unsupported type ${object.runtimeType} when wrapping an IsolateType',
            ),
        }
        as R;
  }

  /// The internal wrapped value.
  final T _value;

  /// Returns the original Dart value by unwrapping this instance.
  T get unwrap => _value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImType<T> &&
          runtimeType == other.runtimeType &&
          _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => 'ImType($_value)';
}

/// A wrapper for [num] values.
///
/// Use [ImNum] to safely transfer a numeric value between isolates.
/// It also provides helper methods for converting the value.
class ImNum extends ImType<num> {
  /// Creates an [ImNum] with the given numeric [value].
  const ImNum(super.value);

  /// Returns the numeric value as a [double].
  double toDouble() => _value.toDouble();

  /// Returns the numeric value as an [int].
  int toInt() => _value.toInt();

  @override
  String toString() => 'ImNum($_value)';
}

/// A wrapper for [String] values.
///
/// Use [ImString] to safely transfer strings between isolates.

class ImString extends ImType<String> {
  /// Creates an [ImString] with the given string [value].
  const ImString(super.value);

  @override
  String toString() => 'ImString($_value)';
}

/// A wrapper for [bool] values.
///
/// Use [ImBool] when transferring boolean values between isolates.
class ImBool extends ImType<bool> {
  /// Creates an [ImBool] with the given boolean [value].
  // ignore: avoid_positional_boolean_parameters
  const ImBool(super.value);

  @override
  String toString() => 'ImBool($_value)';
}

/// A wrapper for lists of [ImType] objects specific to [Object] types.
///
/// This class safely transfers lists between isolates and decodes to a list
/// of original Dart values.
class ImList extends _ImTypedIterable<Object> {
  /// Creates an [ImList] with the provided list of wrapped objects.
  const ImList(super.list);

  /// Converts a plain Dart object into its corresponding [ImList] instance.
  ///
  /// Supported types include these non-nullable Dart types:
  ///   [num], [String], [bool], [List], and [Map] that contain these types.
  ///
  /// Throws an [UnsupportedImTypeException] if the object's type is not supported.
  static ImList wrap<T extends Object?>(Iterable<T> object) {
    return ImType.wrap<ImList>(object);
  }

  /// Converts the wrapped list to an Iterable of the specified IsolateType [T].
  Iterable<T> toIterable<T extends ImType>() => _list.cast<T>();

  /// Converts the wrapped list to a List of the specified IsolateType [T].
  List<T> toList<T extends ImType>() => toIterable<T>().toList();

  /// Converts the wrapped iterable to an unwrapped iterable of type [T].
  ///
  /// Returns a new iterable where each element from the wrapped collection
  /// has been unwrapped and cast to the specified type [T].
  ///
  /// This is useful for accessing the original values without their [ImType] wrappers.
  Iterable<T> toUnwrappedIterable<T extends Object>() {
    return unwrap.cast<T>();
  }

  /// Converts the wrapped iterable to an unwrapped list of type [T].
  ///
  /// Returns a new list where each element from the wrapped collection
  /// has been unwrapped and cast to the specified type [T].
  ///
  /// This is useful for accessing the original values without their [ImType] wrappers
  /// in a standard List collection.
  List<T> toUnwrappedList<T extends Object>() {
    return toUnwrappedIterable<T>().toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImList &&
          runtimeType == other.runtimeType &&
          _listEquals(other._list);

  @override
  int get hashCode => Object.hashAll(_list);

  bool _listEquals(Iterable<ImType<Object>> otherList) {
    if (_list.length != otherList.length) return false;
    final iterator1 = _list.iterator;
    final iterator2 = otherList.iterator;
    while (iterator1.moveNext() && iterator2.moveNext()) {
      if (iterator1.current != iterator2.current) return false;
    }
    return true;
  }

  @override
  String toString() => 'ImList($_list)';
}

/// A wrapper for maps with both keys and values of [Object] types.
///
/// Use [ImMap] to safely transfer maps between isolates.
class ImMap extends _ImTypedMap<Object, Object> {
  /// Creates an [ImMap] with the provided map of wrapped objects.
  const ImMap(super.map);

  /// Converts a plain Dart object into its corresponding [ImMap] instance.
  ///
  /// Supported types include these non-nullable Dart types:
  ///   [num], [String], [bool], [List], and [Map] that contain these types.
  ///
  /// Throws an [UnsupportedImTypeException] if the object's type is not supported.
  static ImMap wrap<K extends Object?, V extends Object?>(Map<K, V> object) {
    return ImType.wrap<ImMap>(object);
  }

  /// Converts the internal wrapped map to a Dart map.
  /// The map keys and values are cast to the specified [ImType] types.
  Map<K, V> toMap<K extends ImType, V extends ImType>() => _map.cast<K, V>();

  /// Converts the wrapped [ImMap] to a Dart [Map] of type `<K, V>`.
  Map<K, V> toDecodedMap<K extends Object, V extends Object>() {
    return toUnwrappedMap<K, V>();
  }

  /// Converts the wrapped [ImMap] to a Dart [Map] of type `<K, V>`.
  Map<K, V> toUnwrappedMap<K extends Object, V extends Object>() {
    return unwrap.cast<K, V>();
  }

  @override
  String toString() => 'ImMap($_map)';
}

/// A generic wrapper for iterables containing [ImType] elements.
///
/// This class wraps each element in an [ImType] and decodes the iterable
/// back to its original unwrapped values.
class _ImTypedIterable<T extends Object> extends ImType<Iterable<T>> {
  /// Creates an instance that wraps the provided iterable of [ImType] elements.
  const _ImTypedIterable(this._list) : super(const []);

  final Iterable<ImType<T>> _list;

  @override
  Iterable<T> get unwrap => _list.map((e) => e.unwrap);
}

/// A generic wrapper for maps that have keys and values wrapped in [ImType].
///
/// This class enables safe transfer of maps between isolates. The [unwrap]
/// getter reconstructs the original map by unwrapping the keys and values.
class _ImTypedMap<K extends Object, V extends Object>
    extends ImType<Map<K, V>> {
  /// Creates an instance that wraps a map with both keys and values as [ImType] objects.
  const _ImTypedMap(this._map) : super(const {});

  /// The internal map with wrapped keys and values.
  final Map<ImType<K>, ImType<V>> _map;

  @override
  Map<K, V> get unwrap => _map.map((k, v) => MapEntry(k.unwrap, v.unwrap));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImMap &&
          runtimeType == other.runtimeType &&
          _mapEquals(other._map);

  @override
  int get hashCode => Object.hashAll(_map.entries);

  bool _mapEquals(Map<ImType<Object>, ImType<Object>> otherMap) {
    if (_map.length != otherMap.length) return false;

    for (final entry in _map.entries) {
      if (!otherMap.containsKey(entry.key) ||
          otherMap[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }
}
