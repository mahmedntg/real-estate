import 'package:flutter/foundation.dart';

const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

/// Build-time override when set, otherwise the page origin on web and the
/// local API port on every other platform.
String get apiBaseUrl {
  if (_apiBaseUrlOverride.isNotEmpty) {
    return _apiBaseUrlOverride;
  }
  if (kIsWeb) {
    return Uri.base.origin;
  }
  return 'http://localhost:8081';
}

String mediaUrl(String? url) {
  if (url == null || url.isEmpty) {
    return '';
  }
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  return '$apiBaseUrl$url';
}
