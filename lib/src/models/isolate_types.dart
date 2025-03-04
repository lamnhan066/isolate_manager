import 'package:equatable/equatable.dart';

/// An abstract wrapper for simple transferable types between the main thread
/// and worker isolates.
///
/// Use this class as the parameter or return type in your isolate communication
/// methods. It provides safe wrapping for these Dart types:
///   - num (wrapped in [IsolateNum])
///   - String (wrapped in [IsolateString])
///   - bool (wrapped in [IsolateBool])
///   - List (wrapped in [IsolateList])
///   - Map (wrapped in [IsolateMap])
///
/// The static [encode] method wraps a Dart object in the appropriate [IsolateType].
sealed class IsolateType<T extends Object?> extends Object with EquatableMixin {
  /// Creates an instance of [IsolateType] holding the provided [_value].
  const IsolateType(this._value);

  /// Converts a plain Dart object into its corresponding [IsolateType] instance.
  ///
  /// Supported types include:
  ///   num, String, bool, List, and Map that contain these types.
  ///
  /// Throws an [UnimplementedError] if the object's type is not supported.
  static R encode<R extends IsolateType<Object?>>(Object? object) {
    return switch (object) {
      final R r => r,
      final num? n => IsolateNum(n),
      final String? s => IsolateString(s),
      final bool? b => IsolateBool(b),
      final List<Object?>? list =>
        IsolateList(list?.map(encode<IsolateType>).toList()),
      final Map<Object?, Object?>? map => IsolateMap(
          map?.map(
            (k, v) => MapEntry(encode<IsolateType>(k), encode<IsolateType>(v)),
          ),
        ),
      _ => throw UnimplementedError(
          'Unsupported type ${object.runtimeType} when encoding an IsolateType',
        ),
    } as R;
  }

  /// The internal wrapped value.
  final T _value;

  /// Returns the original Dart value by unwrapping this instance.
  T get decode => _value;

  @override
  List<Object?> get props => [decode];
}

/// A wrapper for numeric values.
///
/// Use [IsolateNum] to safely transfer a numeric value between isolates.
/// It also provides helper methods for converting the value.
class IsolateNum extends IsolateType<num?> {
  /// Creates an [IsolateNum] with the given numeric [value].
  const IsolateNum(super.value);

  /// Returns the numeric value as a [double], or null if the value is null.
  double? toDouble() => _value?.toDouble();

  /// Returns the numeric value as an [int], or null if the value is null.
  int? toInt() => _value?.toInt();
}

/// A wrapper for [String] values.
///
/// Use [IsolateString] to safely transfer strings between isolates.
class IsolateString extends IsolateType<String?> {
  /// Creates an [IsolateString] with the given string [value].
  const IsolateString(super.value);
}

/// A wrapper for boolean values.
///
/// Use [IsolateBool] when transferring boolean values between isolates.
class IsolateBool extends IsolateType<bool?> {
  /// Creates an [IsolateBool] with the given boolean [value].
  // ignore: avoid_positional_boolean_parameters
  const IsolateBool(super.value);
}

/// A wrapper for lists of [IsolateType] objects specific to [Object?] types.
///
/// This class safely transfers lists between isolates and decodes to a list
/// of original Dart values.
class IsolateList extends _IsolateTypedIterable<Object?> {
  /// Creates an [IsolateList] with the provided list of wrapped objects.
  const IsolateList(super.list);

  /// Converts the wrapped list to an Iterable of the specified IsolateType [T].
  Iterable<T>? toIterable<T extends IsolateType>() => _list?.cast<T>();

  /// Converts the wrapped list to a List of the specified IsolateType [T].
  List<T>? toList<T extends IsolateType>() => toIterable<T>()?.toList();

  /// Converts the decoded value to a iterable of type [T].
  ///
  /// This method attempts to cast the value stored in `decode` to a [Iterable] of type [T].
  /// If `decode` is null, the method returns null.
  Iterable<T>? toDecodedIterable<T>() => decode?.cast<T>();

  /// Converts the decoded value to a list of type [T].
  ///
  /// This method attempts to cast the value stored in `decode` to a [List] of type [T].
  /// If `decode` is null, the method returns null.
  List<T>? toDecodedList<T>() => toDecodedIterable<T>()?.toList();
}

/// A wrapper for maps with both keys and values of [Object?] types.
///
/// Use [IsolateMap] to safely transfer maps between isolates.
class IsolateMap extends _IsolateTypedMap<Object?, Object?> {
  /// Creates an [IsolateMap] with the provided map of wrapped objects.
  const IsolateMap(super.map);

  /// Converts the internal wrapped map to a Dart map.
  /// The map keys and values are cast to the specified [IsolateType] types.
  Map<K, V>? toMap<K extends IsolateType, V extends IsolateType>() =>
      _map?.cast<K, V>();

  /// Converts the wrapped [IsolateMap] to a Dart [Map] of type `<K, V>`.
  Map<K, V>? toDecodedMap<K, V>() => decode?.cast<K, V>();
}

/// A generic wrapper for iterables containing [IsolateType] elements.
///
/// This class wraps each element in an [IsolateType] and decodes the iterable
/// back to its original unwrapped values.
class _IsolateTypedIterable<T> extends IsolateType<Iterable<T>?> {
  /// Creates an instance that wraps the provided iterable of [IsolateType] elements.
  const _IsolateTypedIterable(this._list) : super(null);

  final Iterable<IsolateType<T>>? _list;

  @override
  Iterable<T>? get decode => _list?.map((e) => e.decode);
}

/// A generic wrapper for maps that have keys and values wrapped in [IsolateType].
///
/// This class enables safe transfer of maps between isolates. The [decode]
/// getter reconstructs the original map by unwrapping the keys and values.
class _IsolateTypedMap<K, V> extends IsolateType<Map<K, V>?> {
  /// Creates an instance that wraps a map with both keys and values as [IsolateType] objects.
  const _IsolateTypedMap(this._map) : super(null);

  /// The internal map with wrapped keys and values.
  final Map<IsolateType<K>, IsolateType<V>>? _map;

  @override
  Map<K, V>? get decode => _map?.map((k, v) => MapEntry(k.decode, v.decode));
}
