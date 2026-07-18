import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateInfo {
  final String version;
  final String apkUrl;
  final String updateMessage;

  const UpdateInfo({
    required this.version,
    required this.apkUrl,
    required this.updateMessage,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String? ?? '',
      apkUrl: json['apk_url'] as String? ?? '',
      updateMessage: json['update_message'] as String? ?? '',
    );
  }
}

class UpdateService {
  UpdateService._();

  static const _updateJsonUrl =
      'https://raw.githubusercontent.com/wissem999/guess-the-object/main/update.json';
  static const _lastCheckKey = 'last_update_check_ms';
  static const _checkInterval = Duration(hours: 24);
  static const _requestTimeout = Duration(seconds: 10);

  static Future<UpdateInfo?> checkForUpdate() async {
    if (kIsWeb) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_lastCheckKey);
      final now = DateTime.now().millisecondsSinceEpoch;

      if (lastCheck != null) {
        final elapsed = Duration(milliseconds: now - lastCheck);
        if (elapsed < _checkInterval) return null;
      }

      final response = await http
          .get(Uri.parse(_updateJsonUrl))
          .timeout(_requestTimeout);

      if (response.statusCode != 200) return null;

      final json = _parseJson(response.body);
      if (json == null) return null;

      final info = UpdateInfo.fromJson(json);
      if (info.version.isEmpty || info.apkUrl.isEmpty) return null;

      final currentVersion = await _getCurrentVersion();
      if (currentVersion == null) return null;

      if (!_isNewer(info.version, currentVersion)) {
        await prefs.setInt(_lastCheckKey, now);
        return null;
      }

      await prefs.setInt(_lastCheckKey, now);
      return info;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> downloadAndInstall(
    String apkUrl, {
    void Function(double progress)? onProgress,
  }) async {
    if (kIsWeb) return false;
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/guess_the_object_update.apk';
      final file = File(filePath);

      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(apkUrl));
        final response = await client.send(request).timeout(
              const Duration(minutes: 5),
            );

        if (response.statusCode != 200) return false;

        final contentLength = response.contentLength ?? 0;
        var bytesReceived = 0;

        final sink = file.openWrite();
        await for (final chunk in response.stream) {
          sink.add(chunk);
          bytesReceived += chunk.length;
          if (contentLength > 0) {
            onProgress?.call(bytesReceived / contentLength);
          }
        }
        await sink.flush();
        await sink.close();
      } finally {
        client.close();
      }

      onProgress?.call(1.0);

      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _getCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version;
      final plusIndex = version.indexOf('+');
      return plusIndex > 0 ? version.substring(0, plusIndex) : version;
    } catch (_) {
      return null;
    }
  }

  static bool _isNewer(String latest, String current) {
    try {
      final lParts = latest.split('.').map(int.parse).toList();
      final cParts = current.split('.').map(int.parse).toList();

      while (lParts.length < cParts.length) lParts.add(0);
      while (cParts.length < lParts.length) cParts.add(0);

      for (var i = 0; i < lParts.length; i++) {
        if (lParts[i] > cParts[i]) return true;
        if (lParts[i] < cParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic>? _parseJson(String raw) {
    try {
      final cleaned = raw.trim();
      if (cleaned.isEmpty) return null;

      var buffer = StringBuffer();
      var inString = false;
      var escaped = false;

      for (var i = 0; i < cleaned.length; i++) {
        final c = cleaned[i];
        if (escaped) {
          buffer.write(c);
          escaped = false;
          continue;
        }
        if (c == '\\' && inString) {
          buffer.write(c);
          escaped = true;
          continue;
        }
        if (c == '"') {
          inString = !inString;
          buffer.write(c);
          continue;
        }
        if (!inString) {
          if (c == '/' && i + 1 < cleaned.length && cleaned[i + 1] == '/') {
            while (i < cleaned.length && cleaned[i] != '\n') i++;
            continue;
          }
          if (c == '/' && i + 1 < cleaned.length && cleaned[i + 1] == '*') {
            i += 2;
            while (i < cleaned.length - 1 &&
                !(cleaned[i] == '*' && cleaned[i + 1] == '/')) {
              i++;
            }
            i++;
            continue;
          }
        }
        buffer.write(c);
      }

      final text = buffer.toString();
      final trailingComma = RegExp(r',\s*([}\]])');
      final sanitised = text.replaceAll(trailingComma, r'$1');

      return _simpleJsonDecode(sanitised);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _simpleJsonDecode(String json) {
    json = json.trim();
    if (!json.startsWith('{') || !json.endsWith('}')) return null;

    final result = <String, dynamic>{};
    final inner = json.substring(1, json.length - 1).trim();
    if (inner.isEmpty) return result;

    final entries = _splitTopLevel(inner, ',');
    for (final entry in entries) {
      final colonIdx = entry.indexOf(':');
      if (colonIdx < 0) continue;

      final rawKey = entry.substring(0, colonIdx).trim();
      final rawVal = entry.substring(colonIdx + 1).trim();

      final key = _stripQuotes(rawKey);
      if (key.isEmpty) continue;

      if (rawVal.startsWith('{')) {
        final nested = _simpleJsonDecode(rawVal);
        result[key] = nested;
      } else if (rawVal.startsWith('[')) {
        result[key] = rawVal;
      } else {
        result[key] = _parsePrimitive(rawVal);
      }
    }
    return result;
  }

  static List<String> _splitTopLevel(String s, String delimiter) {
    final parts = <String>[];
    var depth = 0;
    var inStr = false;
    var current = StringBuffer();
    var escaped = false;

    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (escaped) {
        current.write(c);
        escaped = false;
        continue;
      }
      if (c == '\\' && inStr) {
        current.write(c);
        escaped = true;
        continue;
      }
      if (c == '"') {
        inStr = !inStr;
        current.write(c);
        continue;
      }
      if (!inStr) {
        if (c == '{') depth++;
        if (c == '}') depth--;
        if (c == delimiter && depth == 0) {
          parts.add(current.toString());
          current = StringBuffer();
          continue;
        }
      }
      current.write(c);
    }
    if (current.isNotEmpty) parts.add(current.toString());
    return parts;
  }

  static String _stripQuotes(String s) {
    s = s.trim();
    if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
      return s.substring(1, s.length - 1);
    }
    return s;
  }

  static dynamic _parsePrimitive(String s) {
    s = s.trim();
    if (s == 'null') return null;
    if (s == 'true') return true;
    if (s == 'false') return false;

    if (s.startsWith('"') && s.endsWith('"')) {
      return s.substring(1, s.length - 1);
    }

    final asInt = int.tryParse(s);
    if (asInt != null) return asInt;

    final asDouble = double.tryParse(s);
    if (asDouble != null) return asDouble;

    return s;
  }
}
