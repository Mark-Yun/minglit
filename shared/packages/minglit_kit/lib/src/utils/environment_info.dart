import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Collects environment information for bug reports.
/// Each field is collected independently — a failure in one field
/// does not affect others.
Future<Map<String, dynamic>> collectEnvironmentInfo() async {
  final results = await Future.wait([
    _getAppVersion(),
    _getBuildNumber(),
    _getPlatform(),
    _getOsVersion(),
    _getDeviceModel(),
    _getScreenSize(),
    _getNetworkStatus(),
    _getBatteryLevel(),
  ]);
  return {
    'appVersion': results[0],
    'buildNumber': results[1],
    'platform': results[2],
    'osVersion': results[3],
    'deviceModel': results[4],
    'screenSize': results[5],
    'networkStatus': results[6],
    'batteryLevel': results[7],
  };
}

Future<String?> _getAppVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  } on Exception {
    return null;
  }
}

Future<String?> _getBuildNumber() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return info.buildNumber;
  } on Exception {
    return null;
  }
}

Future<String?> _getPlatform() async {
  try {
    if (kIsWeb) return 'web';
    return Platform.operatingSystem;
  } on Exception {
    return null;
  }
}

Future<String?> _getOsVersion() async {
  try {
    if (kIsWeb) return null;
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.version.release;
    } else if (Platform.isIOS) {
      final info = await DeviceInfoPlugin().iosInfo;
      return info.systemVersion;
    }
    return Platform.operatingSystemVersion;
  } on Exception {
    return null;
  }
}

Future<String?> _getDeviceModel() async {
  try {
    if (kIsWeb) return null;
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.model;
    } else if (Platform.isIOS) {
      final info = await DeviceInfoPlugin().iosInfo;
      return info.utsname.machine;
    }
    return null;
  } on Exception {
    return null;
  }
}

Future<String?> _getScreenSize() async {
  try {
    final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
    if (view == null) return null;
    final size = view.physicalSize;
    return '${size.width.toInt()}x${size.height.toInt()}';
  } on Exception {
    return null;
  }
}

Future<String?> _getNetworkStatus() async {
  try {
    final result = await Connectivity().checkConnectivity();
    return result.first.name;
  } on Exception {
    return null;
  }
}

Future<int?> _getBatteryLevel() async {
  try {
    if (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return null;
    }
    return await Battery().batteryLevel;
  } on Exception {
    return null;
  }
}
