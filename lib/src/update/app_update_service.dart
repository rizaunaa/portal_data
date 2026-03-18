import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../supabase_bootstrap.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.mandatory,
    this.notes,
    this.publishedAt,
  });

  final String currentVersion;
  final int currentBuildNumber;
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final bool mandatory;
  final String? notes;
  final DateTime? publishedAt;

  String get targetLabel => '$version+$buildNumber';
}

class AppUpdateService {
  AppUpdateService._();

  static const String _dismissedVersionKey = 'dismissed_update_version';
  static final AppUpdateService instance = AppUpdateService._();

  Future<AppUpdateInfo?> checkForUpdate() async {
    if (updateManifestUrl.isEmpty) {
      return null;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final response = await http.get(Uri.parse(updateManifestUrl));
    if (response.statusCode == 404) {
      throw Exception(
        'Manifest update tidak ditemukan (404). '
        'Pastikan file update.json sudah dipublish ke URL ini: $updateManifestUrl',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Gagal mengambil manifest update (${response.statusCode}).',
      );
    }

    final raw = jsonDecode(response.body);
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Format manifest update tidak valid.');
    }

    final manifest = Map<String, dynamic>.from(raw);
    final version = (manifest['version'] ?? '').toString().trim();
    final buildNumber = _parseInt(manifest['build_number']) ?? 0;
    if (version.isEmpty) {
      throw const FormatException('Field "version" wajib diisi di manifest.');
    }

    final downloadUrl = _resolveDownloadUrl(manifest);
    if (downloadUrl == null || downloadUrl.isEmpty) {
      return null;
    }

    final currentBuildNumber = _parseInt(packageInfo.buildNumber) ?? 0;
    final hasUpdate =
        _compareVersions(version, packageInfo.version) > 0 ||
        (version == packageInfo.version && buildNumber > currentBuildNumber);

    if (!hasUpdate) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final dismissedVersion = prefs.getString(_dismissedVersionKey);
    final mandatory = manifest['mandatory'] == true;
    final targetLabel = '$version+$buildNumber';
    if (!mandatory && dismissedVersion == targetLabel) {
      return null;
    }

    return AppUpdateInfo(
      currentVersion: packageInfo.version,
      currentBuildNumber: currentBuildNumber,
      version: version,
      buildNumber: buildNumber,
      downloadUrl: downloadUrl,
      mandatory: mandatory,
      notes: (manifest['notes'] ?? manifest['changelog'])?.toString(),
      publishedAt: DateTime.tryParse(
        (manifest['published_at'] ?? '').toString(),
      ),
    );
  }

  Future<void> dismiss(AppUpdateInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedVersionKey, info.targetLabel);
  }

  Future<bool> openUpdate(AppUpdateInfo info) async {
    final uri = Uri.tryParse(info.downloadUrl);
    if (uri == null) {
      return false;
    }

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String? _resolveDownloadUrl(Map<String, dynamic> manifest) {
    final downloads = manifest['downloads'];
    final platformKey = _platformKey;
    if (downloads is Map) {
      final normalizedDownloads = Map<String, dynamic>.from(downloads);
      final platformValue = normalizedDownloads[platformKey];
      if (platformValue != null && platformValue.toString().trim().isNotEmpty) {
        return platformValue.toString().trim();
      }

      final fallback = normalizedDownloads['default'];
      if (fallback != null && fallback.toString().trim().isNotEmpty) {
        return fallback.toString().trim();
      }
    }

    final directUrl = manifest['download_url'] ?? manifest['url'];
    return directUrl?.toString().trim();
  }

  String get _platformKey {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  int _compareVersions(String left, String right) {
    final leftParts = _normalizeVersion(left);
    final rightParts = _normalizeVersion(right);
    final maxLength = leftParts.length > rightParts.length
        ? leftParts.length
        : rightParts.length;

    for (var index = 0; index < maxLength; index++) {
      final leftValue = index < leftParts.length ? leftParts[index] : 0;
      final rightValue = index < rightParts.length ? rightParts[index] : 0;
      if (leftValue != rightValue) {
        return leftValue.compareTo(rightValue);
      }
    }

    return 0;
  }

  List<int> _normalizeVersion(String value) {
    return value
        .split('.')
        .map(
          (segment) =>
              _parseInt(segment.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        )
        .toList();
  }

  int? _parseInt(Object? value) {
    if (value == null) {
      return null;
    }

    return int.tryParse(value.toString());
  }
}
