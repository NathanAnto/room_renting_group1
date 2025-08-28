// lib/core/services/app_info_service.dart
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  AppInfoService._();
  static final AppInfoService instance = AppInfoService._();

  PackageInfo? _cached;

  Future<PackageInfo> get packageInfo async {
    _cached ??= await PackageInfo.fromPlatform();
    return _cached!;
  }
}
