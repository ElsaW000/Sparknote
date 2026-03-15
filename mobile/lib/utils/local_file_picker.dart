import 'local_file_picker_stub.dart'
    if (dart.library.html) 'local_file_picker_web.dart';
import 'local_file_picker_stub.dart' show PickedLocalFile;

export 'local_file_picker_stub.dart' show PickedLocalFile;

Future<PickedLocalFile?> pickLocalFile({String? accept}) {
  return pickLocalFileImpl(accept: accept);
}
