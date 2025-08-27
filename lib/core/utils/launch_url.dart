// lib/core/utils/launch_url.dart
import 'package:url_launcher/url_launcher.dart';

Future<bool> safeLaunchUrl(String url) async {
  final uri = Uri.parse(url);
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
