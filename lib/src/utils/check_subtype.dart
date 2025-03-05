import 'package:isolate_manager/isolate_manager.dart';

/// Check if [S] is subtype of [T]
bool isSubtype<S, T>() => <S>[] is List<T>;

/// Check if [S] is subtype of [ImType]
bool isIsolateTypeSubtype<S>() => isSubtype<S, ImType>();
