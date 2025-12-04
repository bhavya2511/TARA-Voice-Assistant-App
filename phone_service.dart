import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

Future<void> makePhoneCall(String number) async {
  final Uri url = Uri(scheme: 'tel', path: number);
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    debugPrint('Error: Could not launch $url');
    throw Exception('Could not launch $url');
  } else {
    debugPrint('Calling number: $number');
  }
}
