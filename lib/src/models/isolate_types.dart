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
sealed class IsolateType extends Object with EquatableMixin {
  /// This `object` only accept `num`, `String`, `bool`, and List, Map of those types.
  ///
  /// Throw [UnimplementedError] if containing any un supported types.
  static R encode<R extends IsolateType>(Object? object) {
    if (object is IsolateType) {
      return object as R;
    }

    return switch (object) {
      num() => IsolateNum(object) as R,
      String() => IsolateString(object) as R,
      bool() => IsolateBool(object) as R,
      List<Object?>() =>
        IsolateList(object.map(IsolateType.encode).toList()) as R,
      Map<Object?, Object?>() => IsolateMap(
          object.map(
            (k, v) => MapEntry(IsolateType.encode(k), IsolateType.encode(v)),
          ),
        ) as R,
      _ => throw UnimplementedError(
          'Contains unsupported type ${object.runtimeType} when encoding an IsolateType',
        ),
    };
  }

  /// Convert to normal types.
  Object? get decode;

  @override
  List<Object?> get props => [decode];
}

/// The [IsolateType] for [num].
class IsolateNum extends IsolateType {
  /// The [IsolateType] for [num].
  IsolateNum(this._value);

  final num? _value;

  @override
  num? get decode => _value;
}

/// The [IsolateType] for [String].
class IsolateString extends IsolateType {
  /// The [IsolateType] for [String].
  IsolateString(this._value);

  final String? _value;

  @override
  String? get decode => _value;
}

/// The [IsolateType] for [bool].
class IsolateBool extends IsolateType {
  /// The [IsolateType] for [bool].
  // ignore: avoid_positional_boolean_parameters
  IsolateBool(this._value);

  final bool? _value;

  @override
  bool? get decode => _value;
}

/// The [IsolateType] for [List] of [IsolateType].
class IsolateList extends IsolateType {
  /// The [IsolateType] for [List] of [IsolateType].
  IsolateList(this._value);

  final List<IsolateType>? _value;

  @override
  List<Object?>? get decode => _value?.map((e) => e.decode).toList();
}

/// The [IsolateType] for [Map] of [IsolateType] as key and value.
class IsolateMap extends IsolateType {
  /// The [IsolateType] for [Map] of [IsolateType] as key and value.
  IsolateMap(this._value);

  final Map<IsolateType, IsolateType>? _value;

  @override
  Map<Object?, Object?>? get decode =>
      _value?.map((k, v) => MapEntry(k.decode, v.decode));
}