import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class AppUpdateInfo {
  final bool updateAvailable;
  final bool isForced;
  final String downloadUrl;
  final String latestVersion;

  AppUpdateInfo({
    required this.updateAvailable,
    required this.isForced,
    required this.downloadUrl,
    required this.latestVersion,
  });
}

class UpdateService {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  /// Initializes Remote Config and fetches the latest values
  static Future<void> initialize() async {
    // We only care about this on Desktop platforms
    if (kIsWeb || (!Platform.isMacOS && !Platform.isWindows)) return;

    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: Duration.zero, // Changed to zero to force immediate updates during testing
    ));

    // Set defaults so the app doesn't crash if it can't reach Firebase
    await _remoteConfig.setDefaults(const {
      'latest_desktop_version': '1.0.0',
      'force_update_required': false,
      'mac_download_url': '',
      'windows_download_url': '',
    });

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint("Failed to fetch remote config: $e");
    }
  }

  /// Compares the local version against the remote config version
  static Future<AppUpdateInfo?> checkForUpdate() async {
    if (kIsWeb || (!Platform.isMacOS && !Platform.isWindows)) return null;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final latestVersion = _remoteConfig.getString('latest_desktop_version');
    final isForced = _remoteConfig.getBool('force_update_required');
    
    String downloadUrl = '';
    if (Platform.isMacOS) {
      downloadUrl = _remoteConfig.getString('mac_download_url');
    } else if (Platform.isWindows) {
      downloadUrl = _remoteConfig.getString('windows_download_url');
    }

    final bool updateAvailable = _isVersionGreaterThan(latestVersion, currentVersion);

    if (updateAvailable) {
      return AppUpdateInfo(
        updateAvailable: true,
        isForced: isForced,
        downloadUrl: downloadUrl,
        latestVersion: latestVersion,
      );
    }

    return null;
  }

  /// Parses semantic version strings (e.g. 1.0.5) to see if v1 > v2
  static bool _isVersionGreaterThan(String v1, String v2) {
    try {
      final v1Parts = v1.split('.').map(int.parse).toList();
      final v2Parts = v2.split('.').map(int.parse).toList();

      for (var i = 0; i < 3; i++) {
        final part1 = i < v1Parts.length ? v1Parts[i] : 0;
        final part2 = i < v2Parts.length ? v2Parts[i] : 0;

        if (part1 > part2) return true;
        if (part1 < part2) return false;
      }
    } catch (e) {
      debugPrint("Version parsing error: $e");
    }
    return false;
  }
}
