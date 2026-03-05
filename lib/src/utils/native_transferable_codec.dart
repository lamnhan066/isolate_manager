import 'dart:collection';
import 'dart:isolate';
import 'dart:typed_data';

const _envelopeMarkerKey = '__im_native_transfer_envelope__';
const _payloadKey = 'payload';
const _packetsKey = 'packets';
const _refMarkerKey = '__im_native_transfer_ref__';
const _typeKey = 't';
const _indexKey = 'i';
const _offsetKey = 'o';
const _lengthKey = 'l';

/// Encodes selected [Uint8List]/[ByteBuffer] values into [TransferableTypedData]
/// references for native isolate transport.
dynamic encodeNativeTransferPayload(
  dynamic payload, {
  List<Object>? transferables,
}) {
  if (transferables == null || transferables.isEmpty) return payload;

  final targetBuffers = HashSet<ByteBuffer>();
  final targetTransferables = HashSet<TransferableTypedData>.identity();
  for (final transferable in transferables) {
    if (transferable is ByteBuffer) {
      targetBuffers.add(transferable);
    } else if (transferable is Uint8List) {
      targetBuffers.add(transferable.buffer);
    } else if (transferable is TransferableTypedData) {
      targetTransferables.add(transferable);
    }
  }

  if (targetBuffers.isEmpty && targetTransferables.isEmpty) return payload;

  final packetIndexes = HashMap<ByteBuffer, int>();
  final transferablePacketIndexes =
      HashMap<TransferableTypedData, int>.identity();
  final packets = <TransferableTypedData>[];

  int ensurePacket(ByteBuffer buffer) {
    final existingIndex = packetIndexes[buffer];
    if (existingIndex != null) return existingIndex;

    final packet = TransferableTypedData.fromList([Uint8List.view(buffer)]);
    packets.add(packet);
    final index = packets.length - 1;
    packetIndexes[buffer] = index;
    return index;
  }

  int ensureTransferablePacket(TransferableTypedData packet) {
    final existingIndex = transferablePacketIndexes[packet];
    if (existingIndex != null) return existingIndex;

    packets.add(packet);
    final index = packets.length - 1;
    transferablePacketIndexes[packet] = index;
    return index;
  }

  dynamic encodeValue(dynamic value) {
    if (value is TransferableTypedData) {
      if (!targetTransferables.contains(value)) return value;
      return <String, Object>{
        _refMarkerKey: true,
        _typeKey: 'ttd',
        _indexKey: ensureTransferablePacket(value),
      };
    }

    if (value is Uint8List) {
      if (!targetBuffers.contains(value.buffer)) return value;
      return <String, Object>{
        _refMarkerKey: true,
        _typeKey: 'u8',
        _indexKey: ensurePacket(value.buffer),
        _offsetKey: value.offsetInBytes,
        _lengthKey: value.lengthInBytes,
      };
    }

    if (value is ByteBuffer) {
      if (!targetBuffers.contains(value)) return value;
      return <String, Object>{
        _refMarkerKey: true,
        _typeKey: 'bb',
        _indexKey: ensurePacket(value),
        _offsetKey: 0,
        _lengthKey: value.lengthInBytes,
      };
    }

    if (value is List) {
      return value.map<Object?>(encodeValue).toList();
    }

    if (value is Map) {
      if (value.keys.every((key) => key is String)) {
        final mapped = <String, Object?>{};
        value.forEach((key, mapValue) {
          mapped[key as String] = encodeValue(mapValue);
        });
        return mapped;
      }

      final mapped = <Object?, Object?>{};
      value.forEach((key, mapValue) {
        mapped[key] = encodeValue(mapValue);
      });
      return mapped;
    }

    return value;
  }

  final encodedPayload = encodeValue(payload);
  if (packets.isEmpty) return payload;

  return <String, Object?>{
    _envelopeMarkerKey: true,
    _payloadKey: encodedPayload,
    _packetsKey: packets,
  };
}

/// Decodes payload encoded by [encodeNativeTransferPayload].
dynamic decodeNativeTransferPayload(dynamic payload) {
  if (payload is! Map) return payload;
  if (payload[_envelopeMarkerKey] != true) return payload;

  final rawPackets = payload[_packetsKey];
  if (rawPackets is! List) return payload[_payloadKey];

  final packets = List<TransferableTypedData?>.filled(rawPackets.length, null);
  final buffers = List<ByteBuffer?>.filled(rawPackets.length, null);

  for (var index = 0; index < rawPackets.length; index++) {
    final rawPacket = rawPackets[index];
    if (rawPacket is! TransferableTypedData) continue;
    packets[index] = rawPacket;
  }

  ByteBuffer? materializeBuffer(int index) {
    if (index < 0 || index >= packets.length) return null;
    if (buffers[index] != null) return buffers[index];
    final packet = packets[index];
    if (packet == null) return null;
    final buffer = packet.materialize();
    buffers[index] = buffer;
    return buffer;
  }

  TransferableTypedData? transferablePacketAt(int index) {
    if (index < 0 || index >= packets.length) return null;
    return packets[index];
  }

  dynamic decodeRef(Map<Object?, Object?> value) {
    final type = value[_typeKey];
    final index = value[_indexKey];
    final offset = value[_offsetKey];
    final length = value[_lengthKey];

    if (type is! String || index is! int) return value;

    if (type == 'ttd') {
      return transferablePacketAt(index) ?? value;
    }

    if (offset is! int || length is! int) return value;
    if (offset < 0 || length < 0) return value;

    final buffer = materializeBuffer(index);
    if (buffer == null) return value;
    if (offset + length > buffer.lengthInBytes) return value;

    if (type == 'u8') {
      return Uint8List.view(buffer, offset, length);
    }
    if (type == 'bb') {
      return buffer;
    }
    return value;
  }

  dynamic decodeValue(dynamic value) {
    if (value is Map && value[_refMarkerKey] == true) {
      return decodeRef(value);
    }

    // TypedData (Uint8List, etc.) implements List<int> — must be checked
    // first so it is returned as-is rather than iterated element-by-element.
    if (value is TypedData) return value;

    if (value is List) {
      return value.map<Object?>(decodeValue).toList();
    }

    if (value is Map) {
      if (value.keys.every((key) => key is String)) {
        final mapped = <String, Object?>{};
        value.forEach((key, mapValue) {
          mapped[key as String] = decodeValue(mapValue);
        });
        return mapped;
      }

      final mapped = <Object?, Object?>{};
      value.forEach((key, mapValue) {
        mapped[key] = decodeValue(mapValue);
      });
      return mapped;
    }

    return value;
  }

  return decodeValue(payload[_payloadKey]);
}
