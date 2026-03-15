import 'dart:typed_data';

class PickedLocalFile {
  final String name;
  final String? mimeType;
  final Uint8List bytes;

  const PickedLocalFile({
    required this.name,
    required this.bytes,
    this.mimeType,
  });
}

Future<PickedLocalFile?> pickLocalFileImpl({String? accept}) async {
  return null;
}
