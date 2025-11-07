import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized runtime configuration for API/Socket base URLs.
/// Persisted so you can change IP/host without rebuilding the app.
class ConfigService {
  ConfigService._internal();
  static final ConfigService I = ConfigService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _kApiBaseUrlKey = 'apiBaseUrl';
  // Production server URL - update this before deployment
  // For production, use your deployed server URL (e.g., https://yourdomain.com)
  // For development, use local IP (e.g., http://192.168.1.100:4000)
  static const String _kDefaultBaseUrl = 'https://mycommunityconnect.onrender.com';

  String _cachedBaseUrl = _kDefaultBaseUrl;
  bool _loaded = false;

  bool _isBroadcastOrInvalid(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https'))
        return true;
      final host = uri.host;
      if (host.isEmpty) return true;
      // Very simple broadcast detection: last octet 255
      final parts = host.split('.');
      if (parts.length == 4 && parts.last == '255') return true;
      return false;
    } catch (_) {
      return true;
    }
  }

  /// Load cached value from storage (only once per app session).
  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final stored = await _storage.read(key: _kApiBaseUrlKey);
    if (stored != null && stored.isNotEmpty) {
      // Force clear old IPs and use new default
      if (stored.contains('10.2.27.4') ||
          stored.contains('10.109.132.6') ||
          _isBroadcastOrInvalid(stored)) {
        // Ignore bad stored value and keep default/cached
        await _storage.delete(key: _kApiBaseUrlKey);
      } else {
        _cachedBaseUrl = stored;
      }
    }
    _loaded = true;
  }

  /// Returns the current API base URL (e.g., http://IP:4000).
  Future<String> getApiBaseUrl() async {
    await _ensureLoaded();
    return _cachedBaseUrl;
  }

  /// Persists and updates the API base URL.
  Future<void> setApiBaseUrl(String url) async {
    if (_isBroadcastOrInvalid(url)) {
      // refuse saving obviously bad urls
      _cachedBaseUrl = _kDefaultBaseUrl;
      await _storage.write(key: _kApiBaseUrlKey, value: _cachedBaseUrl);
    } else {
      _cachedBaseUrl = url;
      await _storage.write(key: _kApiBaseUrlKey, value: url);
    }
  }

  /// For Socket.IO we use the same HTTP base; server upgrades to WS.
  Future<String> getWsBaseUrl() async => getApiBaseUrl();

  /// Synchronous read of the cached URL (best-effort). Useful at startup to avoid
  /// making requests against a wrong default before async storage loads.
  String getCachedBaseUrlSync() => _cachedBaseUrl;
}
