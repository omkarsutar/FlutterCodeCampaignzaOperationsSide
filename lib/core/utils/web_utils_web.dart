// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

String getHref() => web.window.location.href;
String getHash() => web.window.location.hash;

void replaceState(dynamic data, String title, String url) {
  web.window.history.replaceState(data, title, url);
}

MemoryInfo? getMemoryInfo() {
  try {
    final performance = web.window.performance;
    // Note: performance.memory is non-standard but often available in Chromium
    final memory = (performance as dynamic).memory;
    if (memory != null) {
      return MemoryInfo(
        memory.usedJSHeapSize.toDouble(),
        memory.jsHeapSizeLimit.toDouble(),
      );
    }
  } catch (e) {
    // Silent fail if performance.memory is not supported
  }
  return null;
}

class MemoryInfo {
  final double usedJSHeapSize;
  final double jsHeapSizeLimit;
  MemoryInfo(this.usedJSHeapSize, this.jsHeapSizeLimit);
}
