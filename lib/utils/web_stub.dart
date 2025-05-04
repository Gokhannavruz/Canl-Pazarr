// This file provides stub implementations for native platform features
// that are not available on the web platform

// Stub for File class from dart:io
class File {
  final String path;

  File(this.path);

  static Future<bool> existsSync(String path) async => false;
  Future<bool> exists() async => false;
  Future<File> create({bool recursive = false}) async => this;
  Future<File> writeAsString(String contents) async => this;
  Future<String> readAsString() async => '';
  Future<List<int>> readAsBytes() async => [];
}

// Add a stub for Platform class from dart:io
class Platform {
  // Platform detection stubs - all false on web
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isFuchsia => false;
  static bool get isLinux => false;
  static bool get isMacOS => false;
  static bool get isWindows => false;

  // Always return true for web
  static bool get isWeb => true;

  // Other common Platform properties
  static String get operatingSystem => 'web';
  static String get operatingSystemVersion => 'web';
  static String get localHostname => 'localhost';
  static Map<String, String> get environment => <String, String>{};
}

// Add any other needed stub classes here that are used in your app
// and are imported from platform-specific libraries like dart:io or dart:ffi 