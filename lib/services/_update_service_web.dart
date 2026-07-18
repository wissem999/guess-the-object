import 'dart:async';

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

  static Future<UpdateInfo?> checkForUpdate() async => null;

  static Future<bool> downloadAndInstall(
    String apkUrl, {
    void Function(double progress)? onProgress,
  }) async =>
      false;
}
