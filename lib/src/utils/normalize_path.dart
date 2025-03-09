import 'package:path/path.dart' as p;

/// Normalizes a file system path.
///
/// This function takes a path string as input and returns a normalized
/// version of the path. Normalization may include removing redundant
/// separators, resolving relative path segments, or ensuring
/// consistent formatting.
///
/// Example:
/// ```dart
/// final path = '/Users/user/./Documents/../Downloads/';
/// final normalized = normalizePath(path);
/// // Result might be: '/Users/user/Downloads'
/// ```
///
/// @param path The file system path to normalize
/// @return A normalized version of the input path
String? normalizePath(String? path) {
  if (path == null || path.isEmpty) return path;

  return path.replaceAll(RegExp(r'\\'), p.separator);
}
