import 'package:path/path.dart' as p;

/// Normalizes a file system path.
///
/// This function will replace all `/` and `\` with the current platform separator.
///
/// ```dart
/// // On windows
/// print(normalizePath('C:/Users/username\\Desktop')); // C:\Users\username\Desktop
/// ```
String? normalizePath(String? path) {
  if (path == null || path.isEmpty) return path;

  return path.replaceAll(RegExp(r'[/\\]'), p.separator);
}
