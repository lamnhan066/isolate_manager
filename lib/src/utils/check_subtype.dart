import 'package:isolate_manager/isolate_manager.dart';

/// Check if [S] is subtype of [ImType]
bool isIsolateTypeSubtype<S>() => <S>[] is List<ImType>;
