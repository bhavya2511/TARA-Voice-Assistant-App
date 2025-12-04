import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

Future<void> openWhatsApp({required String phone, required String message}) async {
  final encodedMessage = Uri.encodeComponent(message);
  final Uri url = Uri.parse('https://wa.me/$phone?text=$encodedMessage');
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    debugPrint('Error launching WhatsApp');
    throw Exception('Could not launch WhatsApp');
  }
}
