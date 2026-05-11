import 'web_utils_stub.dart' if (dart.library.html) 'web_utils_web.dart' as impl;

String getHref() => impl.getHref();
String getHash() => impl.getHash();
void replaceState(dynamic data, String title, String url) => impl.replaceState(data, title, url);
impl.MemoryInfo? getMemoryInfo() => impl.getMemoryInfo();

typedef MemoryInfo = impl.MemoryInfo;
