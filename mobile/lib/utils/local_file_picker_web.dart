import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'local_file_picker_stub.dart';

Future<PickedLocalFile?> pickLocalFileImpl({String? accept}) async {
  final input = html.FileUploadInputElement()..multiple = false;
  if (accept != null && accept.isNotEmpty) {
    input.accept = accept;
  }
  input.click();
  await input.onChange.first;
  final file = input.files?.first;
  if (file == null) {
    return null;
  }
  final reader = html.FileReader();
  final completer = Completer<PickedLocalFile?>();
  reader.onLoadEnd.listen((_) {
    final result = reader.result;
    Uint8List? bytes;
    if (result is ByteBuffer) {
      bytes = Uint8List.view(result);
    } else if (result is Uint8List) {
      bytes = result;
    } else if (result is List<int>) {
      bytes = Uint8List.fromList(result);
    }
    if (bytes == null) {
      completer.complete(null);
      return;
    }
    completer.complete(
      PickedLocalFile(
        name: file.name,
        mimeType: file.type.isEmpty ? null : file.type,
        bytes: bytes,
      ),
    );
  });
  reader.readAsArrayBuffer(file);
  return completer.future;
}
