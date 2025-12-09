// lib/services/phone_service.dart
import 'package:url_launcher/url_launcher.dart';

class PhoneService {
  /// Make a call (opens dialer or places call depending on Uri and device permissions).
  Future<bool> makeCall(String phoneNumber) async {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return false;
    final uri = Uri(scheme: 'tel', path: cleaned);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
    } catch (e) {}
    return false;
  }
}
