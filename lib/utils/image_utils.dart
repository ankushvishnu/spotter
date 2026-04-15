import 'package:flutter/foundation.dart';

/// Supabase project URL — keep in sync with supabase_config.dart
const _supabaseUrl = 'https://wflqpizdtuiiaicfuuby.supabase.co';

/// Returns a CORS-safe image URL.
///
/// On Flutter Web, XMLHttpRequest is used for network images, which requires
/// the server to include `Access-Control-Allow-Origin` headers. Third-party
/// hosts like randomuser.me do NOT send these headers, causing CORS failures.
///
/// This proxy routes such URLs through our Supabase Edge Function which re-
/// serves the image with proper CORS headers. On mobile/desktop the URL is
/// returned unchanged (native HTTP stack has no CORS restriction).
String corsProxyUrl(String? url) {
  if (url == null || url.isEmpty) return '';

  // Only proxy on web AND only for domains known to block CORS
  if (kIsWeb && _needsProxy(url)) {
    final encoded = Uri.encodeComponent(url);
    return '$_supabaseUrl/functions/v1/proxy-image?url=$encoded';
  }

  return url;
}

bool _needsProxy(String url) {
  const blockedDomains = [
    'randomuser.me',
  ];
  return blockedDomains.any((d) => url.contains(d));
}
