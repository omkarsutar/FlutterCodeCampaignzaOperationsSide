import 'package:flutter/foundation.dart';

Future<void> saveFile({
  required Uint8List bytes,
  required String fileName,
}) async {
  // On mobile/desktop, we don't need a fallback yet as the printing package usually works.
  // This stub is primarily to allow the project to compile with conditional imports.
  debugPrint('FileSaveHelper: Mobile/Stub implementation called for $fileName');
}
