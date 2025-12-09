// lib/services/whatsapp_service.dart
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class WhatsappService {
  /// Open WhatsApp chat with phone number and prefilled message.
  /// phoneNumber must be numeric with country code (e.g. 91xxxxxxxxxx)
  Future<bool> sendMessage(String phoneNumber, String message) async {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return false;
    final encoded = Uri.encodeComponent(message);
    // try whatsapp:// URI first
    final schemeUri = Uri.parse('whatsapp://send?phone=$cleaned&text=$encoded');
    try {
      if (await canLaunchUrl(schemeUri)) {
        await launchUrl(schemeUri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {}

    // fallback to wa.me
    final webUri = Uri.parse('https://wa.me/$cleaned?text=$encoded');
    try {
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {}

    return false;
  }
}
