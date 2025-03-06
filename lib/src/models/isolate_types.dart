// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

// TODO(lamnhan066): Remove the deprecated types in the stable release
// coverage:ignore-start

/// An abstract wrapper for simple transferable types between the main thread
/// and worker isolates.
///
/// Use this class as the parameter or return type in your isolate communication
/// methods. It provides safe wrapping for these Dart types:
///   - num (wrapped in [ImNum])
///   - String (wrapped in [ImString])
///   - bool (wrapped in [ImBool])
///   - List (wrapped in [ImList])
///   - Map (wrapped in [ImMap])
///
/// The static `wrap` method wraps a Dart object in the appropriate [ImType].
@Deprecated(
  'Use `ImType` instead. This class will be removed in the stable release.',
)
typedef IsolateType<T extends Object> = ImType<T>;

/// A wrapper for numeric values.
/// Use [ImNum] to safely transfer a numeric value between isolates.
/// It also provides helper methods for converting the value.
@Deprecated(
  'Use `ImNum` instead. This class will be removed in the stable release.',
)
typedef IsolateNum = ImNum;

/// A wrapper for [String] values.
/// Use [ImString] to safely transfer strings between isolates.
@Deprecated(
  'Use `ImString` instead. This class will be removed in the stable release.',
)
typedef IsolateString = ImString;

/// A wrapper for boolean values.
/// Use [ImBool] when transferring boolean values between isolates.
@Deprecated(
  'Use `ImBool` instead. This class will be removed in the stable release.',
)
typedef IsolateBool = ImBool;

/// A wrapper for lists of [ImType] objects specific to [Object] types.
/// This class safely transfers lists between isolates and decodes to a list
/// of original Dart values.
@Deprecated(
  'Use `ImList` instead. This class will be removed in the stable release.',
)
typedef IsolateList = ImList;

/// A wrapper for maps with both keys and values of [Object] types.
/// Use [ImMap] to safely transfer maps between isolates.
@Deprecated(
  'Use `ImMap` instead. This class will be removed in the stable release.',
)
typedef IsolateMap = ImMap;
// coverage:ignore-end

/// An abstract wrapper for simple transferable types between the main thread
/// and worker isolates.
///
/// Use this class as the parameter or return type in your isolate communication
/// methods. It provides safe wrapping for these Dart types:
///   - num (wrapped in [ImNum])
///   - String (wrapped in [ImString])
///   - bool (wrapped in [ImBool])
///   - List (wrapped in [ImList])
///   - Map (wrapped in [ImMap])
///
/// The static [wrap] method wraps a Dart object in the appropriate [ImType].
sealed class ImType<T extends Object> {
  /// Creates an instance of [ImType] holding the provided [_value].
  const ImType(this._value);

  /// Converts a plain Dart object into its corresponding [ImType] instance.
  ///
  /// Supported types include:
  ///   num, String, bool, List, and Map that contain these types.
  ///
  /// Throws an [UnimplementedError] if the object's type is not supported.
  static R wrap<R extends ImType<Object>>(Object object) {
    return switch (object) {
      final R r => r,
      final num n => ImNum(n),
      final String s => ImString(s),
      final bool b => ImBool(b),
      final Iterable<dynamic> list => ImList(
          list.map((e) => wrap(e as Object)),
        ),
      final Map<dynamic, dynamic> map => ImMap(
          map.map((k, v) => MapEntry(wrap(k as Object), wrap(v as Object))),
        ),
      _ => throw UnimplementedError(
          'Unsupported type ${object.runtimeType} when wrapping an IsolateType',
        ),
    } as R;
  }

  /// Converts a plain Dart object into its corresponding [ImType] instance.
  ///
  /// Supported types include:
  ///   num, String, bool, List, and Map that contain these types.
  ///
  /// Throws an [UnimplementedError] if the object's type is not supported.
  @Deprecated(
    'Use `IsolateType.wrap` instead. This method will be removed in the stable release.',
  )
  static R encode<R extends ImType<Object>>(Object object) {
    return wrap<R>(object);
  }

  /// The internal wrapped value.
  final T _value;

  /// Returns the original Dart value by unwrapping this instance.
  @Deprecated(
    'Use `unwrap` instead. This getter will be removed in the stable release.',
  )
  T get decode => unwrap;

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

/// A wrapper for numeric values.
///
/// Use [ImNum] to safely transfer a numeric value between isolates.
/// It also provides helper methods for converting the value.
class ImNum extends ImType<num> {
  /// Creates an [ImNum] with the given numeric [value].
  const ImNum(super.value);

  /// Returns the numeric value as a [double], or null if the value is null.
  double toDouble() => _value.toDouble();

  /// Returns the numeric value as an [int], or null if the value is null.
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

/// A wrapper for boolean values.
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
  /// Only supports `String`, `bool`, `num` and `List`, `Map` of those types.
  /// Throws an [UnimplementedError] if the object's type is not supported.
  static ImList wrap<T extends Object>(Iterable<T> object) {
    return ImType.wrap<ImList>(object);
  }

  /// Converts the wrapped list to an Iterable of the specified IsolateType [T].
  Iterable<T> toIterable<T extends ImType>() => _list.cast<T>();

  /// Converts the wrapped list to a List of the specified IsolateType [T].
  List<T> toList<T extends ImType>() => toIterable<T>().toList();

  /// Converts the decoded value to a iterable of type [T].
  ///
  /// This method attempts to cast the value stored in `decode` to a [Iterable] of type [T].
  /// If `decode` is null, the method returns null.
  Iterable<T> toDecodedIterable<T extends Object>() {
    return unwrap.cast<T>();
  }

  /// Converts the decoded value to a list of type [T].
  ///
  /// This method attempts to cast the value stored in `decode` to a [List] of type [T].
  /// If `decode` is null, the method returns null.
  List<T> toDecodedList<T extends Object>() {
    return toDecodedIterable<T>().toList();
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
  /// Only supports `String`, `bool`, `num` and `List`, `Map` of those types.
  /// Throws an [UnimplementedError] if the object's type is not supported.
  static ImMap wrap<K extends Object, V extends Object>(
    Map<K, V> object,
  ) {
    return ImType.wrap<ImMap>(object);
  }

  /// Converts the internal wrapped map to a Dart map.
  /// The map keys and values are cast to the specified [ImType] types.
  Map<K, V> toMap<K extends ImType, V extends ImType>() => _map.cast<K, V>();

  /// Converts the wrapped [ImMap] to a Dart [Map] of type `<K, V>`.
  Map<K, V> toDecodedMap<K extends Object, V extends Object>() {
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
