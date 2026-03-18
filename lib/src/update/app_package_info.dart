import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppPackageInfo {
  const AppPackageInfo({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;
}

class AppPackageInfoService {
  AppPackageInfoService._();

  static const MethodChannel _channel = MethodChannel(
    'portal_data/app_package_info',
  );
  static final AppPackageInfoService instance = AppPackageInfoService._();

  static const String _fallbackVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '0.1.0',
  );
  static const String _fallbackBuildNumber = String.fromEnvironment(
    'APP_BUILD_NUMBER',
    defaultValue: '1',
  );

  Future<AppPackageInfo> fromPlatform() async {
    if (kIsWeb) {
      return _fallbackInfo;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidInfo();
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return _fallbackInfo;
    }
  }

  Future<AppPackageInfo> _androidInfo() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getAppPackageInfo',
      );
      if (result == null) {
        return _fallbackInfo;
      }

      final version = (result['version'] ?? '').toString().trim();
      final buildNumber = (result['buildNumber'] ?? '').toString().trim();
      if (version.isEmpty || buildNumber.isEmpty) {
        return _fallbackInfo;
      }

      return AppPackageInfo(version: version, buildNumber: buildNumber);
    } catch (_) {
      return _fallbackInfo;
    }
  }

  AppPackageInfo get _fallbackInfo {
    return const AppPackageInfo(
      version: _fallbackVersion,
      buildNumber: _fallbackBuildNumber,
    );
  }
}
