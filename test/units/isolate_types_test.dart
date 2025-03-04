import 'package:isolate_manager/src/models/isolate_types.dart';
import 'package:test/test.dart';

void main() {
  group('IsolateType.encode', () {
    test('wraps num as IsolateNum', () {
      const numValue = 42;
      final encoded = IsolateType.encode(numValue);
      expect(encoded, isA<IsolateNum>());
      expect((encoded as IsolateNum).decode, equals(numValue));
      expect(encoded.toDouble(), equals(numValue.toDouble()));
      expect(encoded.toInt(), equals(numValue));
    });

    test('wraps String as IsolateString', () {
      const strValue = 'Hello, Isolate!';
      final encoded = IsolateType.encode(strValue);
      expect(encoded, isA<IsolateString>());
      expect((encoded as IsolateString).decode, equals(strValue));
    });

    test('wraps bool as IsolateBool', () {
      const boolValue = true;
      final encoded = IsolateType.encode(boolValue);
      expect(encoded, isA<IsolateBool>());
      expect((encoded as IsolateBool).decode, equals(boolValue));
    });

    test('wraps List as IsolateList and can decode iterable', () {
      final listValue = [1, 'two', false];
      final encoded = IsolateType.encode(listValue);
      expect(encoded, isA<IsolateList>());
      final isolateList = encoded as IsolateList;
      final wrappedList = isolateList.toList<IsolateType>();
      expect(wrappedList, isNotNull);
      // Test that each element is wrapped accordingly.
      expect(wrappedList![0], isA<IsolateNum>());
      expect(wrappedList[1], isA<IsolateString>());
      expect(wrappedList[2], isA<IsolateBool>());
      // Test decoded value.
      final decoded = isolateList.decode;
      expect(decoded, equals(listValue));
    });

    test('wraps Map as IsolateMap and can decode map', () {
      final mapValue = {
        'a': 1,
        'b': false,
        'c': 'three',
      };
      final encoded = IsolateType.encode(mapValue);
      expect(encoded, isA<IsolateMap>());
      final isolateMap = encoded as IsolateMap;
      // Test that toMap returns a map with proper key/value types.
      final wrappedMap = isolateMap.toMap<IsolateString, IsolateType>();
      expect(wrappedMap, isA<Map<IsolateString, IsolateType>>());
      // Since keys are encoded, we check the decoded map.
      final decoded = isolateMap.decode;
      expect(decoded, equals(mapValue));
    });

    test('throws UnimplementedError for unsupported types', () {
      final unsupportedValue = DateTime.now();
      expect(
        () => IsolateType.encode(unsupportedValue),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  group('IsolateList helper methods', () {
    test('toIterable and toDecodedList work correctly', () {
      final listValue = [10, 20, 30];
      final encoded = IsolateType.encode(listValue) as IsolateList;

      // Use toList to get the wrapped items.
      final wrappedList = encoded.toList<IsolateType>();
      expect(wrappedList, isA<List<IsolateType>>());
      expect(wrappedList!.length, equals(listValue.length));

      // Using toDecodedList to return the original values.
      final decodedList = encoded.toDecodedList<num>();
      expect(decodedList, equals(listValue));
    });
  });

  group('IsolateMap helper methods', () {
    test('toMap and toDecodedMap work correctly', () {
      final mapValue = {
        'x': 100,
        'y': 200,
      };
      final encoded = IsolateType.encode(mapValue) as IsolateMap;

      // Testing toMap which casts the internal map to specified types.
      final wrappedMap = encoded.toMap<IsolateString, IsolateType>();
      expect(wrappedMap, isA<Map<IsolateString, IsolateType>>());
      expect(wrappedMap!.length, equals(mapValue.length));

      // Using toDecodedMap to get original Map.
      final decodedMap = encoded.toDecodedMap<String, int>();
      expect(decodedMap, equals(mapValue));
    });
  });
}
