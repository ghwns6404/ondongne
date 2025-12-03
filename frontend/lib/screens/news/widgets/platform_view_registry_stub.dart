// Stub implementation for non-web platforms
class PlatformViewRegistry {
  void registerViewFactory(String viewId, dynamic Function(int) callback) {
    throw UnsupportedError('Platform views are not supported on this platform');
  }
}

final platformViewRegistry = PlatformViewRegistry();





