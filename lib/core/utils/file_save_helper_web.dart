import 'dart:typed_data';
import 'dart:js_interop';
// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

Future<void> saveFile({
  required Uint8List bytes,
  required String fileName,
}) async {
  final blob = web.Blob([bytes.toJS].toJS);
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
