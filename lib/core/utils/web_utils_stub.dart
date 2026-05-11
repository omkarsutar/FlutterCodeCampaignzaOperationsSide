String getHref() => '';
String getHash() => '';
void replaceState(dynamic data, String title, String url) {}
MemoryInfo? getMemoryInfo() => null;

class MemoryInfo {
  final double usedJSHeapSize;
  final double jsHeapSizeLimit;
  MemoryInfo(this.usedJSHeapSize, this.jsHeapSizeLimit);
}
