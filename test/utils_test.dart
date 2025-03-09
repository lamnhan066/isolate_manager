import 'package:isolate_manager/src/utils/normalize_path.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Utils', () {
    test('normalizePath', () {
      // Test with null value
      expect(normalizePath(null), isNull);

      // Test with empty string
      expect(normalizePath(''), equals(''));

      // Test with normal paths
      expect(
        normalizePath('/path/to/file'),
        equals('/path${p.separator}to${p.separator}file'),
      );
      expect(
        normalizePath(r'\path\to\file'),
        equals('${p.separator}path${p.separator}to${p.separator}file'),
      );

      // Test with mixed separators
      expect(
        normalizePath(r'/path\to/file'),
        equals('/path${p.separator}to${p.separator}file'),
      );

      // Test with consecutive separators
      expect(
        normalizePath(r'//path\\to//file'),
        equals(
          '${p.separator}${p.separator}path${p.separator}${p.separator}to${p.separator}${p.separator}file',
        ),
      );

      // Test with no separators
      expect(normalizePath('filename'), equals('filename'));
    });
  });
}
