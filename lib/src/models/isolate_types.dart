import 'package:equatable/equatable.dart';

/// Use [IsolateType] in your parameter and return types to ensure that the value
/// is transferable between the main app and the Workers. So the `IsolateManager`
/// will work correctly on both VM and Web.
///
/// Includes:
///   [IsolateNum] for [num]
///   [IsolateString] for [String]
///   [IsolateBool] for [bool]
///   [IsolateMap] for [Map]
///   [IsolateList] for [List]
sealed class IsolateType with EquatableMixin {
  /// This `object` only accept `num`, `String`, `bool`, and List, Map of those types.
  ///
  /// Throw [UnimplementedError] if containing any un supported types.
  static IsolateType encode(Object? object) {
    return switch (object) {
      num() => IsolateNum(object),
      String() => IsolateString(object),
      bool() => IsolateBool(object),
      List<Object?>() => IsolateList(object.map(IsolateType.encode).toList()),
      Map<Object?, Object?>() => IsolateMap(
          object.map(
            (k, v) => MapEntry(IsolateType.encode(k), IsolateType.encode(v)),
          ),
        ),
      _ => throw UnimplementedError(),
    };
  }

  /// Convert to normal types.
  Object get decode;

  @override
  List<Object> get props => [decode];
}

/// The [IsolateType] for [num].
class IsolateNum extends IsolateType {
  /// The [IsolateType] for [num].
  IsolateNum(this._value);

  final num _value;

  @override
  num get decode => _value;
}

/// The [IsolateType] for [String].
class IsolateString extends IsolateType {
  /// The [IsolateType] for [String].
  IsolateString(this._value);

  final String _value;

  @override
  String get decode => _value;
}

/// The [IsolateType] for [bool].
class IsolateBool extends IsolateType {
  /// The [IsolateType] for [bool].
  // ignore: avoid_positional_boolean_parameters
  IsolateBool(this._value);

  final bool _value;

  @override
  bool get decode => _value;
}

/// The [IsolateType] for [List] of [IsolateType].
class IsolateList<T extends IsolateType> extends IsolateType {
  /// The [IsolateType] for [List] of [IsolateType].
  IsolateList(this._value);

  final List<T> _value;

  @override
  List<Object> get decode => _value.map((e) => e.decode).toList();
}

/// The [IsolateType] for [Map] of [IsolateType] as key and value.
class IsolateMap<K extends IsolateType, V extends IsolateType>
    extends IsolateType {
  /// The [IsolateType] for [Map] of [IsolateType] as key and value.
  IsolateMap(this._value);

  final Map<K, V> _value;

  @override
  Map<Object, Object> get decode =>
      _value.map((k, v) => MapEntry(k.decode, v.decode));
}
